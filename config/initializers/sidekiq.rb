Sidekiq.default_worker_options = { 'backtrace' => true }
Sidekiq.average_scheduled_poll_interval = ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].to_i if ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].present?
