Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']
  config.host    = ENV['AIRBRAKE_HOST']
  config.port    = ENV['AIRBRAKE_PORT'].to_i
  config.secure  = config.port == 443
  config.async do |notice|
    AirbrakeJob.perform_later(notice.to_xml)
  end
  # Uncomment to test airbrake in development mode
  #~ config.development_environments = []
end
