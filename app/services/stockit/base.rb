require 'nestful'

module Stockit::Base

  def post(url, params = {}, options = {})
    options = default_options.merge(options)
    begin
      Nestful.post( url, params, options ).as_json
    rescue Nestful::ConnectionError => ex # catches all Nestful errors
      stockit_connection_error
    end
  end

  def put(url, params = {}, options = {})
    options = default_options.merge(options)
    begin
      Nestful.put( url, params, options ).as_json
    rescue Nestful::ConnectionError => ex # catches all Nestful errors
      stockit_connection_error
    end
  end

  def get(url, params = {}, options = {})
    options = default_options.merge(options)
    begin
      Nestful.get( url, params, options ).as_json
    rescue Nestful::ConnectionError => ex # catches all Nestful errors
      stockit_connection_error
    end
  end

  def stockit_connection_error
    {
      "errors" => {
        connection_error: "Could not contact Stockit, try again later."
      }
    }
  end

  def headers
    raise(ValueError, "Stockit api_token cannot be blank") if api_token.blank?
    { "token" => api_token }
  end

  def endpoint
    Rails.application.secrets.base_urls["stockit"] # no trailing slash
  end

  def api_token
    Rails.application.secrets.stockit["api_token"]
  end

  def default_options
    { format: :json, headers: headers }
  end

  def url_for(path)
    endpoint + path
  end

  class ValueError < StandardError; end

end
