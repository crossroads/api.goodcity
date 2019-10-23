require 'stockit/base'

module Stockit
  class ItemDetailSync

    include Stockit::Base

    attr_accessor :detail, :detail_type

    def initialize(detail)
      @detail = detail
      @detail_type = detail.class.name.underscore
    end

    class << self
      def create(detail)
        new(detail).create if detail
      end

      def update(detail)
        new(detail).update if detail
      end
    end

    def create
      url = url_for("/api/v1/#{detail_type.pluralize}")
      post(url, detail_params)
    end

    def update
      url = url_for("/api/v1/#{detail_type.pluralize}/update")
      put(url, detail_params)
    end

    private

    def detail_params
      params = detail.attributes.except("id", "created_at", "updated_at", "stockit_id", "updated_by_id")
      params["item_id"] =  detail&.package&.stockit_id
      params["#{detail_type}_id"] = detail.stockit_id
      params["country_id"] = Country.find_by(id: params["country_id"])&.stockit_id
      { "#{detail_type}": params }
    end
  end
end
