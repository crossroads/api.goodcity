Sidekiq.default_job_options = { 'backtrace' => true }
Sidekiq.average_scheduled_poll_interval = ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].to_i if ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].present?

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
  # Turn down Sidekiq's verbose logging
  config.logger.level = Logger::WARN
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
end
