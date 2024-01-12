Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 0.5

  # scrub data using settings from config/initializers/filter_parameter_logging.rb
  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, hint|
    filter.filter(event.to_hash)
  end

  # filter out SQL queries from spans with sensitive data
  config.before_send_transaction = lambda do |event, hint|
    event.spans.each do |span|
      span[:description] = '<FILTERED>' if span[:op].start_with?('db')
    end
    event
  end
end
