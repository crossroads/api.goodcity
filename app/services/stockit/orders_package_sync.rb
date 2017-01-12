require 'stockit/base'

module Stockit
  class OrdersPackageSync

    include Stockit::Base

    attr_accessor :package, :errors, :offset, :per_page

    def initialize(package = nil, orders_package = nil, offset = nil, per_page = nil)
      @package = package
      @orders_package = orders_package
      @errors = {}
      @offset = offset
      @per_page = per_page
    end

    class << self
      def create(package, orders_package)
        new(package, orders_package).create
      end

      def update(package, orders_package)
        new(package, orders_package).update
      end

      def delete(package, orders_package)
        new(package, orders_package).delete
      end
    end

    def create
      if package.inventory_number.present?
        url = url_for("/api/v1/items")
        post(url, stockit_params.merge!({generate_q_inventory_number: true}))
      end
    end

    def update
      if package.inventory_number.present?
        url = url_for("/api/v1/items/update")
        put(url, stockit_params.merge!({update_gc_orders_package: true, orders_package_id: @orders_package.id, orders_package_state: @orders_package.state}))
      end
    end

    def delete
      url = url_for("/api/v1/items/destroy")
      put(url, { gc_orders_package_id: @orders_package.id })
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
        quantity: @orders_package.quantity,
        code_id: package.package_type.try(:stockit_id),
        inventory_number: add_stockit_prefix(package.inventory_number),
        case_number: package.case_number.blank? ? nil : package.case_number,
        condition: package_condition,
        grade: package.grade,
        description: package.notes,
        location_id: package.location.try(:stockit_id),
        id: package.stockit_id,
        designation_id: @orders_package.order.try(:stockit_id),
        designated_on: @orders_package.created_at,
        gc_orders_package_id: @orders_package.id,
        parent_id: package.stockit_id,
        sent_on: @orders_package.sent_on
      }
    end

    def package_params
      {
        length: package.length,
        width: package.width,
        height: package.height,
        description: package.notes
      }
    end

    def package_condition
      condition = package.try(:donor_condition).try(:name_en) ||
        package.try(:item).try(:donor_condition).try(:name_en)
      case condition
      when "New" then "N"
      when "Lightly Used" then "M"
      when "Heavily Used" then "U"
      when "Broken" then "B"
      end
    end

  end
end
