Sidekiq.default_job_options = { 'backtrace' => true }

# better for Splunk integration
module Sidekiq
  class Logger < ::Logger
    module Formatters
      class CustomJson < Base
        def call(severity, time, program_name, message)
          hash = {
            time: time.utc.iso8601(3),
            pid: ::Process.pid,
            tid: tid,
            level: severity,
            message: message,
            origin: "sidekiq",
          }
          c = ctx
          hash["ctx"] = c unless c.empty?
          Sidekiq.dump_json(hash) << "\n"
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
  config.logger.level = Logger::WARN
  config.logger.formatter = Sidekiq::Logger::Formatters::CustomJson.new
  config.average_scheduled_poll_interval = ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].to_i if ENV["SIDEKIQ_AVERAGE_SCHEDULED_POLL_INTERVAL"].present?
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
end
