# config/initializers/rack_timeout.rb

# insert middleware wherever you want in the stack, optionally pass
# initialization arguments, or use environment variables
Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 15
