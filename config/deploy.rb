# config valid only for Capistrano 3.1
lock '3.3.5'

set :application, 'goodcity_server'
set :repo_url, 'git@github.com:crossroads/goodcity-server-prototype.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/rails/goodcity_server'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{ config/database.yml .env }

# Default value for linked_dirs is []
#~ set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log tmp/pids tmp/cache}
set :bundle_binstubs, nil

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# How many processes do we want? Each one has 20 threads in production.
set :sidekiq_processes, 2

set :rvm_ruby_version, '2.1.5'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

end

# cap production invoke[db:migrate]
# cap production invoke[db:reset]
desc "Invoke a rake command on the remote server: cap production invoke[db:migrate]"
task :invoke, [:command] => 'deploy:set_rails_env' do |task, args|
  on primary(:app) do
    within current_path do
      with :rails_env => fetch(:rails_env) do
        rake args[:command]
      end
    end
  end
end

namespace :redis do
  desc "Report Redis status"
  task :status do
    on primary(:app) do
      execute 'redis-cli info'
    end
  end
end

namespace :passenger do
  desc "Report passenger status"
  task :status do
    on roles(:app) do
      within current_path do
        execute "passenger-memory-stats"
      end
    end
  end
end
