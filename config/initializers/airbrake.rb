if defined?(Airbrake)
  airbrake_yml = YAML.load_file("#{Rails.root}/config/airbrake.yml")
  Airbrake.configure do |config|
    config.api_key = airbrake_yml['api_key']
    config.host    = airbrake_yml['host']
    config.port    = airbrake_yml['port']
    config.secure  = config.port == 443
    #config.async   = true # TODO should use sucker_punch but doesn't work
  end
end
