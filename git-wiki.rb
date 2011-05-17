$KCODE = "UTF-8"

require "sinatra/base"
require "haml"
require "grit"
require "rdiscount"

module GitWiki
  class << self
    attr_accessor :homepage, :extension, :repository
  end

  def self.new(repository, extension, homepage)
    self.homepage   = homepage
    self.extension  = extension
    self.repository = Grit::Repo.new(repository)

    App
  end

  class PageNotFound < Sinatra::NotFound
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  class Page
    def self.find_all
      return [] if repository.tree.contents.empty?
      collect_blobs(repository.tree)
    end
    
    def self.collect_blobs(tree)
      blobs = tree.contents.collect do |blob_or_tree|
        if blob_or_tree.class == Grit::Blob
          new(blob_or_tree)
        else
          blobs = { blob_or_tree.name.to_sym => collect_blobs(blob_or_tree) }
        end
      end
      blobs.compact
    end

    def self.find(name)
      page_blob = find_blob(name)
      raise PageNotFound.new(name) unless page_blob
      new(page_blob, name)
    end

    def self.find_or_create(name, image = false)
      find(name)
    rescue PageNotFound
      new(create_blob_for(name, image), name)
    end

    def self.css_class_for(name)
      find(name)
      "exists"
    rescue PageNotFound
      "unknown"
    end

    def self.repository
      GitWiki.repository || raise
    end

    def self.extension
      GitWiki.extension || raise
    end
    
    def self.image_extensions
      /(png|jpg|jpeg|gif)$/
    end

    def self.find_blob(page_name)
      found_ext   = extension
      ext_matches = page_name.match(Page.image_extensions)
      found_ext   = "" if !ext_matches.nil?
      repository.tree / (page_name + found_ext)
    end
    private_class_method :find_blob

    def self.create_blob_for(page_name, image = false)
      blob_name = page_name + extension
      blob_name = page_name if image
      
      p blob_name
      
      Grit::Blob.create(repository, {
        :name => blob_name,
        :data => ""
      })
    end
    private_class_method :create_blob_for

    def initialize(blob, path_on_site = "")
      @blob = blob
      @site_path = path_on_site
      if path_on_site.match(Page.image_extensions).nil?
        @image = false
      else
        @image = true
      end
    end

    def to_html
      RDiscount.new(content).to_html
    end

    def to_s
      name
    end

    def new?
      @blob.id.nil?
    end

    def name
      @blob.name.gsub(/#{File.extname(@blob.name)}$/, '')
    end
    
    def site_path
      @site_path
    end
    
    def title
      content.to_s.split("\n")[0]
    end

    def content
      if @blob.class == Grit::Blob
        @blob.data
      else
        @blob.name
      end
    end

    def update_content(new_content, editor_name)
      return if new_content == content
      create_new_dirs_structure(file_name) # create a new directories if they don't exist yet
      File.open(file_name, "w") { |f| f << new_content }
      add_to_index_and_commit!(editor_name)
    end
    
    def revisions
      Page.repository.commits_since.map { |commit|
        commit_hash = commit.stats.to_hash
        {
          :date      => commit.date,
          :message   => commit.message.gsub(/'.+'/, ""),
          :additions => commit_hash["additions"],
          :deletions => commit_hash["files"].first[3]
        } if commit_hash["files"].first.first == site_path + GitWiki.extension
      }.compact
    end
    
    def mime_type
      @blob.mime_type
    end
    
    def list_images
      path = Page.repository.working_dir + "/" + @site_path
      if File.exists?(path)
        Dir.open(path).entries.map { |e| e if (!e.match(Page.image_extensions).nil? && File.file?(path + "/" + e)) }.compact
      else
        []
      end
    end

    private
      def add_to_index_and_commit!(editor_name)
        Dir.chdir(self.class.repository.working_dir) {
          self.class.repository.add(file_name)
          self.class.repository.commit_index(commit_message(editor_name))
        }
      end
      
      def file_name
        extension = self.class.extension
        extension = "" if @image
        
        unless @site_path.empty?
          File.join(self.class.repository.working_dir, @site_path + extension)
        else
          File.join(self.class.repository.working_dir, name + extension)
        end
      end

      def commit_message(editor_name)
        new? ? "created '#{file_name}' by #{editor_name}" : "updated '#{file_name}' by #{editor_name}"
      end
      
      # prepare and creates new directory structure for the files
      def create_new_dirs_structure(file_name)
        dir_path_pieces = file_name.gsub(self.class.repository.working_dir, "").split("/").compact
        dir_path_pieces.pop(1) # remove filename.markdown
        
        dir_path_pieces.reduce("") do |memo,dir_piece|
          directory_path = self.class.repository.working_dir + "/" + memo + "/" + dir_piece
          
          unless File.exist?(directory_path)
            Dir.mkdir(directory_path)
          end
          
          memo + "/" + dir_piece
        end
      end
  end

  class App < Sinatra::Base
    set :app_file, __FILE__
    set :haml, { :format        => :html5,
                 :attr_wrapper  => '"'     }
    enable :inline_templates
    enable :sessions
    
    not_found do
      haml :not_found
    end
    
    error PageNotFound do
      page = request.env["sinatra.error"].name.gsub /\/$/, ""
      redirect "/#{page}/edit"
    end

    before do
      content_type "text/html", :charset => "utf-8"
    end

    get "/" do
      redirect "/" + GitWiki.homepage
    end

    get "/pages" do
      @pages = Page.find_all
      haml :list
    end

    get "/*/edit" do
      # why browser want to "GET /favicon.ico/edit" ?
      protected! if params[:splat][0] != "/favicon.ico"
      @page = Page.find_or_create(params[:splat][0])
      @page.list_images
      haml :edit
    end
    
    get "/*/history" do
      @page = Page.find(params[:splat][0])
      haml :history
    end

    get "/*" do
      @page = Page.find(params[:splat][0])
      matched_ext = params[:splat][0].match(Page.image_extensions)
      if !matched_ext.nil?
        content_type "image/" + matched_ext[0]
        @page.content
      else
        haml :show
      end
    end
    
    post "/preview" do
      css  = '<link rel="stylesheet" href="/stylesheets/blueprint/screen.css" media="screen, projection" type="text/css"/>'
      css += '<link rel="stylesheet" href="/stylesheets/blueprint/print.css" media="print" type="text/css"/>'
      css += '<!--[if IE]><link rel="stylesheet" href="/stylesheets/blueprint/ie.css" type="text/css"/><![endif]-->'
      css += '<link rel="stylesheet" href="/stylesheets/application.css" media="screen, projection" type="text/css"/>'
      css + '<div class="page container">' + RDiscount.new(params[:data]).to_html + '</div>'
    end
    
    post "/upload" do
      content_type "application/json"
      
      begin
        protected!
        name     = params[:qqfile]
        sitepath = params[:sitepath]
        page     = Page.find_or_create(sitepath + "/" + name, image = true)
        page.update_content(request.body.read, @auth.credentials.first)
        "{success:true}"
      rescue
        "{success:false}"
      end
    end

    post "/*" do
      protected! if params[:splat][0] != "/favicon.ico"
      
      @page = Page.find_or_create(params[:splat][0])
      @page.update_content(params[:body], @auth.credentials.first)
      
      redirect "/#{@page.site_path}"
    end
    
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [ 401, haml(:not_authorized) ])
      end
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      
      if @auth.provided? && @auth.basic? && @auth.credentials
        $CONFIG["users"].any? { |account| @auth.credentials == [ account["username"], account["password"] ] }
      end
    end

    private
      def title(title = nil)
        @title = title.to_s unless title.nil?
        @title
      end

      def list_item(page, directory = "")
        ret = ""
        
        if page.class == GitWiki::Page
          ret += %Q{<li><a class="page_name" href="/#{directory}#{page}">#{page.title}</a></li>} if page.mime_type == "text/plain"
        elsif page.class == Hash
          page.each_pair { |key,value|
            directory += key.to_s + "/"
            ret += '<li><a class="page_name" href="/' + directory.to_s + '">' + key.to_s + "</a><ul>" + list_item(value, directory) + "</ul>" + "</li>"
          }
        elsif page.class == Array
          page.each { |value|
            ret += list_item(value, directory)
          }
        end
        
        ret
      end
  end
end

__END__
@@ layout
!!!
%html
  %head
    %title= title
    %meta(http-equiv="Content-Type" content="text/html; charset=utf-8")
    = '<link rel="icon" href="/favicon.ico" type="image/x-icon"/>'
    = '<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon"/>'
    = '<link rel="stylesheet" href="/stylesheets/blueprint/screen.css" media="screen, projection" type="text/css"/>'
    = '<link rel="stylesheet" href="/stylesheets/blueprint/print.css" media="print" type="text/css"/>'
    = '<!--[if IE]><link rel="stylesheet" href="/stylesheets/blueprint/ie.css" type="text/css"/><![endif]-->'
    = '<!--[if IE]><style type="text/css">#topmenu{background-color:#fff;}</style><![endif]-->'
    = '<link rel="stylesheet" href="/stylesheets/application.css" media="screen, projection" type="text/css"/>'
    = '<link href="http://fonts.googleapis.com/css?family=Droid+Serif" rel="stylesheet" type="text/css"/>'
    = '<script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>'
    = '<script type="text/javascript" src="http://static.evernote.com/noteit.js"></script>'
    = '<script type="text/javascript">/*<![CDATA[*/var _gaq=_gaq||[];_gaq.push(["_setAccount","' + $CONFIG["ga_account"] + '"]);_gaq.push(["_trackPageview"]);(function(){var ga=document.createElement("script");ga.type="text/javascript";ga.async=true;ga.src=("https:"==document.location.protocol?"https://ssl":"http://www")+".google-analytics.com/ga.js";var s=document.getElementsByTagName("script")[0];s.parentNode.insertBefore(ga,s);})();/*]]>*/</script>' if $CONFIG["use_ga_tracking"]
  %body
    #wrap
      #main.container.page
        = yield
    #footer.container
      .span-24.last
        = 'Code based on <a href="https://github.com/sr/git-wiki" target="_blank">git-wiki</a> project. You can get copy of code of this wiki at <a href="https://github.com/cr0t/git-wiki" target="_blank">github.com</a>.'
    #topmenu
      .container
        .span-10
          %a{ :href => "/#{GitWiki.homepage}" }
            = $CONFIG["logo_text"]
        .span-5
          %a{ :href => "/pages" } all pages
        .span-4#like_button
          = '<iframe src="http://www.facebook.com/plugins/like.php?href=' + request.url.to_s + '&amp;layout=button_count&amp;show_faces=true&amp;width=140&amp;action=recommend&amp;font&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none;overflow:hidden;width:140px;height:21px;" allowTransparency="true"></iframe>'
        .span-3#tweet_button
          = '<a href="http://twitter.com/share" class="twitter-share-button" data-count="horizontal" data-via="kuznetsovsg">Tweet</a>'
        .span-2.last#evernote_button
          = '<a href="#" onclick="Evernote.doClip({styling:\'none\',contentId:\'content\'});return false;"><img src="http://static.evernote.com/article-clipper.png" alt="Clip in Evernote" style="vertical-align:bottom"></a>'

@@ show
- title @page.title
#content
  ~"#{@page.to_html}"
  #edit
    %a{:href => "/#{@page.site_path}/history", :rel => "nofollow"} History
    |
    %a{:href => "/#{@page.site_path}/edit", :rel => "nofollow"} Edit this page

@@ history
- title @page.title
#content
  %h2 Revisions history of <strong>#{@page.title}</strong> page
  - @page.revisions.each do |rev|
    .span-24.last
      .span-7 #{rev[:date]}
      .span-11 #{rev[:message]}
      .span-6.last <small>#{rev[:additions]} strings added, #{rev[:deletions]} strings deleted</small>

@@ edit
- title "Editing #{@page.title}"
<link href="/markitup/skins/markitup/style.css" rel="stylesheet" type="text/css"/>
<link href="/markitup/sets/markdown/style.css" rel="stylesheet" type="text/css"/>
<script type="text/javascript" src="http://code.jquery.com/jquery-1.6.min.js"></script>
<script type="text/javascript" src="/markitup/jquery.markitup.js"></script>
<script type="text/javascript" src="/javascripts/fileuploader.js"></script>
<script type="text/javascript" src="/javascripts/edit.js"></script>
<script type="text/javascript">
#{"/*<![CDATA[*/"}
var LOCAL_IMAGES = [#{@page.list_images.map {|i| "'" + i + "'"}.join(",") }];
#{"/*]]>*/"}
</script>
#file-uploader
  %noscript
    %p Please enable JavaScript to use advanced file uploader.
    %form{ :action=>"/upload", :method=>"post", :enctype=>"multipart/form-data" }
      %input{ :type=>"file", :name=>"upfile" }
      %input{ :type=>"submit", :value=>"Upload" }
%h1= title
<br clear="all"/>
%form{:method => 'POST', :action => "/#{@page.site_path}"}
  %p
    %textarea{:id => "markdown", :name => "body", :rows => 30}= @page.content
  %p
    %input.submit{:type => :submit, :value => "Save as the newest version"}
    or
    %a.cancel{:href=>"/#{@page.site_path}"} cancel

@@ list
- title "Listing pages"
%h1 All pages
- if @pages.empty?
  %p No pages found.
- else
  %ul#list
    - @pages.each do |page|
      = list_item(page)

@@ not_found
- title "Not Found"
%h1 Not Found
%p This site has been changed. Please, go to <a href="/Home">Home page</a> and surf the new wiki site.

@@ not_authorized
- title "Not authorized"
%h1 Not Authorized
%p Not authorized. Please, go to <a href="/Home">Home page</a> and surf the new wiki site.
