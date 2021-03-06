require 'bundler/capistrano'

set :stages, %w(staging production)
set :default_stage, 'staging'
require 'capistrano/ext/multistage'

server 'api', :app, :db, primary: true

set :user, 'api'
set :application, 'recalls_api'
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, 'git'
set :repository,  "git@github.com:GSA-OCSIT/#{application}.git"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after 'deploy:restart', 'deploy:cleanup'

namespace :deploy do
  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/airbrake.yml #{release_path}/config/airbrake.yml"
    run "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
    run "ln -nfs #{shared_path}/config/sunspot.yml #{release_path}/config/sunspot.yml"
  end
  after 'deploy:finalize_update', 'deploy:symlink_config'

  task :notify_newrelic, roles: :app do
    local_user = ENV['USER'] || ENV['USERNAME']
    run "cd #{current_path} ; bundle exec newrelic deployments -u \"#{local_user}\" -r #{current_revision}"
  end
  after 'deploy:restart', 'deploy:notify_newrelic'

  task :start, roles: :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :restart, roles: :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

require './config/boot'
require 'airbrake/capistrano'
