Rails.application.config.middleware.insert_after Rails::Rack::Logger, Rack::Cors, :logger => Rails.logger do
  allow do
    origins '*'
    resource '*', headers: :any,
                  methods: [:get, :post, :put, :delete, :options]
  end
end
