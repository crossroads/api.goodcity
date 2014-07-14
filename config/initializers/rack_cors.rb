Rails.application.config.middleware.use Rack::Cors do
  allow do
    origins 'app.goodcity.hk', 'localhost:3000', 'localhost:4200'
    resource '*', headers: :any,
                  methods: [:get, :post, :put, :delete, :options]
  end
end
