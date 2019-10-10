require 'stockit/base'

module Stockit
  class ItemDetailSync

    include Stockit::Base

    attr_accessor :detail

    def initialize(detail)
      @detail = detail
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

    protected

    def detail_type
      detail.class.name.downcase
    end

    def detail_params
      detail.attributes.except("id", "stockit_id", "created_at", "updated_at", "updated_by_id")
    end
  end
end
