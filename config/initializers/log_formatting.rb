require 'lograge/formatters/json'

if %w(staging production).include?(Rails.env)

  Rails.application.configure do

    # Lograge settings
    config.lograge.enabled = true
    # config.lograge.base_controller_class = 'ActionController::API' # Required when on Rails 5
    config.lograge.custom_options = lambda do |event|
      options = event.payload.slice(:request_ip, :user_id, :app_name, :app_version)
      options.merge!(event.payload[:params].except(*%w(controller action format id))) if event.payload[:method] == "GET"
      options
    end

    config.lograge.formatter = Lograge::Formatters::Json.new

    # Wire in a custom formatter for Rails.logger.info(...) - can take hash or string args
    Rails.logger           = ActiveSupport::Logger.new("#{Rails.root}/log/#{Rails.env}.log", level: :info)
    Rails.logger.formatter = ->(severity, time, progname, msg = '') {
      return '' if msg.blank?
      log_hash = {}
      log_hash['time'] = time.iso8601(3)
      log_hash['level'] = severity
      log_hash['progname'] = progname if progname.present?
      log_hash['msg'] = msg # string or hash
      "#{log_hash.to_json}\n"
    }

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

  end
end
