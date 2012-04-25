APP_PATH = "/var/www/com.summercode.wiki"

rails_env = ENV["RAILS_ENV"] || "development"

# 2 workers and 1 master
worker_processes 2

working_directory APP_PATH + "/current" # available in 0.94.0+

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true

# Restart any workers that haven't responded in 60 seconds
timeout 60

# Listen on a Unix data socket
listen "/tmp/.unicorn_wiki_sock", :backlog => 64

pid APP_PATH + "/shared/pids/unicorn.pid"
stderr_path APP_PATH + "/shared/log/unicorn.stderr.log"
stdout_path APP_PATH + "/shared/log/unicorn.stdout.log"

##
# REE
# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_exec do |server|
 ENV['BUNDLE_GEMFILE'] = APP_PATH + "/current/Gemfile"
end

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill(:QUIT, File.read(old_pid).to_i)
    rescue
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ##
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
