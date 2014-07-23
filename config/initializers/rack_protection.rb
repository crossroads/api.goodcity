Rails.application.config.middleware.use Rack::Protection, :except => [:session_hijacking, :remote_token]
