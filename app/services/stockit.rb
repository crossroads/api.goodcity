require 'nestful'

module Stockit
  class Browse

    attr_accessor :id, :params, :errors

    def initialize(id = nil, params = {})
      @params = params
      @id = id
      @errors = {}
    end

    def add_item
      url = url_for("/api/v1/items")
      res = post(url, params)
    end

    private

    def get(url, params = {}, options = {})
      options = default_options.merge(options)
      begin
        Nestful.get( url, params, options ).as_json
      rescue Nestful::ConnectionError => ex # catches all Nestful errors
        { error: ex.message }
      end
    end

    def post(url, params = {}, options = {})
      options = default_options.merge(options)
      begin
        Nestful.post( url, params, options ).as_json
      rescue Nestful::ConnectionError => ex # catches all Nestful errors
        { error: ex.message }
      end
    end

    def headers
      { }
    end

    def endpoint
      "http://localhost:3000" # no trailing slash
    end

    def default_options
      { format: :json, headers: headers }
    end

    def url_for(path)
      endpoint + path
    end

    class ValueError < StandardError; end

  end

end
