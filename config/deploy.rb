require 'bundler/capistrano'

set :rvm_ruby_string, 'ruby-1.9.3-p125@git-wiki'
set :rvm_type, :system
require 'rvm/capistrano'

set :application, "com.summercode.wiki"
set :repository,  "git@github.com:cr0t/git-wiki.git"

set :scm, :git

role :web, "summercode.com"

set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
set :keep_releases, 3

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart do
    run "/etc/unicorns/wiki restart"
  end

  after "deploy:update" do
    deploy::cleanup
  end
end
