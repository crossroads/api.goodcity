Rails.application.config.middleware.use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any,
                  methods: [:get, :post, :put, :delete, :options]
  end
end
