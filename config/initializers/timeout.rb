Rack::Timeout.timeout = Rails.env.development? ? 0 : 30 # Abort requests that take too long... Puma needs help doing this
Rack::Timeout.unregister_state_change_observer(:logger) # Turn off the logging
