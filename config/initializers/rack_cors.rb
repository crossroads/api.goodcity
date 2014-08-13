Rails.application.config.middleware.use Rack::Cors do
  allow do
    #~ if Rails.env == 'production'
      #~ origins 'app.goodcity.hk'
    #~ else
      #~ origins '*'
    #~ end
    origins '*'
    resource '*', headers: :any,
                  methods: [:get, :post, :put, :delete, :options]
  end
end
