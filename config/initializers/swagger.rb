require 'sprockets/railtie'

if Rails.env.staging? || Rails.env.development?
  GrapeSwaggerRails.options.app_name      = 'GoodCity'
  GrapeSwaggerRails.options.url           = '/api/docs/v2.json?type=swagger'
  GrapeSwaggerRails.options.api_auth      = 'bearer'
  GrapeSwaggerRails.options.api_key_name  = 'Authorization'
  GrapeSwaggerRails.options.api_key_type  = 'header'

  GrapeSwaggerRails.options.before_action do
    GrapeSwaggerRails.options.app_url = request.protocol + request.host_with_port
  end
end