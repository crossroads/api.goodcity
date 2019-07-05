
if %w(development staging production).include?(Rails.env)

  require_relative '../../lib/logging/log_formatter'
  
  Rails.application.configure do
    
    # Lograge settings
    config.lograge.enabled = true
    # config.lograge.base_controller_class = 'ActionController::API' # Required when on Rails 5
    config.lograge.custom_options = lambda do |event|
      options = event.payload.slice(:request_ip, :user_id, :app_name, :app_version)
      options.merge!(event.payload[:params].except(*%w(controller action format id))) if event.payload[:method] == "GET"
      options
    end

    # Wire in the Rails.logger custom formatter
    Rails.logger           = ActiveSupport::Logger.new("#{Rails.root}/log/#{Rails.env}.log", level: :info)
    Rails.logger.formatter = LogFormatter.new

    # Turn down ActiveJob's verbose logging
    ActiveSupport.on_load :active_job do
      class ActiveJob::Logging::LogSubscriber
        private def args_info(job)
          # override this method to filter arguments shown in app log
          ''
        end
      end
      ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new("#{Rails.root}/log/active-job-#{Rails.env}.log", level: :warn))
    end

    # Turn down Sidekiq's verbose logging
    # https://github.com/mperham/sidekiq/wiki/Logging#default-logger-and-verboseness
    Sidekiq::Logging.logger.level = :warn

  end
end