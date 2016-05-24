require 'stockit/base'

module Stockit
  class ItemSync

    include Stockit::Base

    attr_accessor :package, :errors

    def initialize(package)
      @package = package
      @errors = {}
    end

    class << self
      def create(package)
        new(package).create
      end

      def update(package)
        new(package).update
      end

      def delete(package)
        new(package).delete
      end
    end

    def create
      if package.inventory_number.present?
        url = url_for("/api/v1/items")
        post(url, stockit_params)
      end
    end

    def update
      if package.inventory_number.present?
        url = url_for("/api/v1/items/update")
        put(url, stockit_params)
      end
    end

    def delete
      inventory_number = package # package is actually inventory_number
      if inventory_number.present?
        url = url_for("/api/v1/items/destroy")
        put(url, {inventory_number: add_stockit_prefix(inventory_number)})
      end
    end

    private

    def add_stockit_prefix(inventory_number)
      return "X#{inventory_number}" if !!((inventory_number || "")[0..0] =~ /[0-9]/)
      inventory_number
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
        code_id: package.package_type.try(:stockit_id),
        inventory_number: add_stockit_prefix(package.inventory_number),
        condition: package_condition,
        grade: package.grade,
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

    def package_condition
      condition = package.donor_condition.name_en || package.item.donor_condition.name_en
      case condition
      when "New" then "N"
      when "Lightly Used" then "M"
      when "Heavily Used" then "U"
      when "Broken" then "B"
      end
    end

  end

end
