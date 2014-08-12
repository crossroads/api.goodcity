if defined?(Airbrake)
  Airbrake.configure do |config|
    config.api_key = ENV['AIRBRAKE_API_KEY']
    config.host    = ENV['AIRBRAKE_HOST']
    config.port    = ENV['AIRBRAKE_PORT'].to_i
    config.secure  = config.port == 443
    #config.async   = true # TODO should use sucker_punch but doesn't work
  end
end
