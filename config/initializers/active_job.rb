require "active_job"
ActiveJob::Base.queue_adapter = :sidekiq

# Once we go to Rails 4.2, uncomment below and remove the above lines
#~ Rails.application.configure do
  #~ config.active_job.queue_adapter = :sidekiq
#~ end

Sidekiq.default_worker_options = { 'backtrace' => true }
