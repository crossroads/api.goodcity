require 'nestful'

module Stockit
  class Browse

    attr_accessor :gc_package, :errors

    def initialize(gc_package)
      @gc_package = gc_package
      @errors = {}
    end

    def add_item
      url = url_for("/api/v1/items")
      post(url, stockit_params)
    end

    def remove_item
      url = url_for("/api/v1/items/destroy")
      destroy(url, delete_request_params)
    end

    private

    def delete_request_params
      {
        inventory_number: gc_package.inventory_number
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
        quantity: gc_package.quantity,
        code_id: gc_package.package_type.code,
        inventory_number: gc_package.inventory_number,
        condition: item_condition,
        description: gc_package.package_type.name,
        grade: "B",
        location_id: 117
      }
    end

    def package_params
      {
        length: gc_package.length,
        width: gc_package.width,
        height: gc_package.height
      }
    end

    def item_condition
      case gc_package.item.donor_condition.name_en
      when "New" then "N"
      when "Lightly Used" then "M"
      when "Heavily Used" then "N"
      when "Broken" then "B"
      end
    end

    def post(url, params = {}, options = {})
      options = default_options.merge(options)
      begin
        Nestful.post( url, params, options ).as_json
      rescue Nestful::ConnectionError => ex # catches all Nestful errors
        {
          "errors": {
            connection_error: "Could not contact Stockit, try again later."
          }
        }
      end
    end

    def destroy(url, params = {}, options = {})
      options = default_options.merge(options)
      begin
        Nestful.put( url, params, options ).as_json
      rescue Nestful::ConnectionError => ex # catches all Nestful errors
        {
          "errors": {
            connection_error: "Could not contact Stockit, try again later."
          }
        }
      end
    end

    def headers
      { }
    end

    def endpoint
      Rails.application.secrets.base_urls["stockit"] # no trailing slash
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
