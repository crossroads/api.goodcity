require "active_job"

Rails.application.configure do
  config.active_job.queue_adapter = :sidekiq
end

Sidekiq.default_worker_options = { 'backtrace' => true }
