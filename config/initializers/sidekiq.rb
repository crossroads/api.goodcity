Sidekiq.default_job_options = { 'backtrace' => true }

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
  # Turn down Sidekiq's verbose logging
  config.logger.level = Logger::WARN
  config.average_scheduled_poll_interval = 7 #ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].to_i if ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].present?
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
end
