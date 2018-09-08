namespace :sidekiq do
  desc 'Start sidekiq'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :systemctl, :start, :sidekiq
    end
  end

  desc 'Stop sidekiq'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :systemctl, :stop, :sidekiq
    end
  end

  desc 'Restart sidekiq'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end

  desc 'Status of sidekiq'
  task :status do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :systemctl, :status, :sidekiq
    end
  end

  task :add_default_hooks do
    after 'deploy:updated', 'sidekiq:stop'
    after 'deploy:reverted', 'sidekiq:stop'
    after 'deploy:published', 'sidekiq:start'
  end
end

namespace :deploy do
  before :starting, :insert_sidekiq_hooks do
    invoke 'sidekiq:add_default_hooks'
  end
end
