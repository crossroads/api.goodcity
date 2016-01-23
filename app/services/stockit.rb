require 'nestful'

module Stockit
  class Browse

    attr_accessor :package, :errors

    def self.create(package)
    end

    def initialize(package = nil)
      @package = package
      @errors = {}
    end

    def add_item
      url = url_for("/api/v1/items")
      post(url, stockit_params)
    end

    def update_item
      url = url_for("/api/v1/items/update")
      put(url, stockit_params)
    end

    def remove_item
      if package
        url = url_for("/api/v1/items/destroy")
        put(url, delete_request_params)
      end
    end

    def get_locations
      url = url_for("/api/v1/locations")
      get(url)
    end

    private

    def delete_request_params
      {
        inventory_number: package
      }
    end

    def stockit_params
      {
        item: item_params,
        package: package_params
      }
    end

    def item_params
      {
        quantity: package.quantity,
        code_id: package.package_type.code,
        inventory_number: package.inventory_number,
        condition: item_condition,
        description: package.notes,
        location_id: package.location.try(:stockit_id)
      }
    end

    def package_params
      {
        length: package.length,
        width: package.width,
        height: package.height,
        description: package.notes,
      }
    end

    def item_condition
      case package.item.donor_condition.name_en
      when "New" then "N"
      when "Lightly Used" then "M"
      when "Heavily Used" then "U"
      when "Broken" then "B"
      end
    end

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
        "errors": {
          connection_error: ": could not contact Stockit, try again later."
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

end
