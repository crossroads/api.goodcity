namespace :sidekiq do
  desc 'Custom rake task to clear all sidekiq queues'
  task clear: :environment do
    Sidekiq.redis { |conn| conn.flushdb }
  end
end