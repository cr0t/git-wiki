require 'bundler/capistrano'
require 'rvm/capistrano'

set :rvm_ruby_string, 'ruby-1.9.3-p429@git-wiki'
set :rvm_path,        '/usr/local/rvm'
set :rvm_type,        :system

set :application, 'com.summercode.wiki'
set :repository,  'git@github.com:cr0t/git-wiki.git'
set :branch,      :master

set :scm, :git

role :web, '85.10.236.42'

set :use_sudo,      false
set :deploy_to,     "/var/www/#{application}"
set :keep_releases, 5
set :ssh_options,   { :forward_agent => true }

namespace :deploy do
  desc 'Deploy your application'
  task :default do
    update
    restart
  end

  desc 'Zero-downtime restart of Unicorn'
  task :restart do
    run "sudo /etc/init.d/unicorn_#{application} restart"
  end

  task :start do
    run "sudo /etc/init.d/unicorn_#{application} start"
  end

  task :stop do
    run "sudo /etc/init.d/unicorn_#{application} stop"
  end

  after 'deploy:update' do
    deploy::cleanup
  end
end
