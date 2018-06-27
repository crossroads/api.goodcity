module InventoryOperations
  module Goodcity
    class Dispatch < Base
      attr_accessor :current_packages_location_id, :dispatched_packages_location,
        :packages_location_qty_mapping

      def initialize(options = {})
        super
        self.current_packages_location_id = options[:packages_location_id]
        self.dispatched_packages_location = package.dispatched_packages_location(dispatched_location_id) || package.packages_locations.new(location_id: dispatched_location_id)
        self.packages_location_qty_mapping = options[:packages_location_qty_mapping]
      end

      def dispatch
        if is_singletone_package
          singleton_package_dispatch
        else
          multi_quantity_package_dispatch
        end
      end

      def singleton_package_dispatch
        if orders_package.dispatched?
          package.errors.add('Item', I18n.t('orders_package.already_dispatched')) and package
        else
          assign_attributes_to_orders_package
          save_changes_and_sync_to_stockit
          package.dispatch_stockit_item(orders_package, true)
        end
      end

      def multi_quantity_package_dispatch
        assign_attributes_to_orders_package
        update_packages_locations_for_multi_quantity
        package.dispatch_stockit_item(orders_package, true)
      end

      def update_packages_locations_for_singletone
        if orders_package.save
          destroy_stale_packages_locations
          save_dispatched_location_changes
        end
      end

      def update_packages_locations_for_multi_quantity
        package.deduct_quantity_from_packages_locations(packages_location_qty_mapping)
        save_dispatched_location_changes
      end

      def assign_attributes_to_orders_package
        orders_package.sent_on    = Time.now
        orders_package.updated_by = current_user
        orders_package.state      = 'dispatched'
      end

      def destroy_stale_packages_locations
        package.packages_locations.where.not(id: dispatched_packages_location.try(:id)).destroy_all
      end

      def save_dispatched_location_changes
        dispatched_packages_location.quantity = quantity
        dispatched_packages_location.reference_to_orders_package = orders_package.try(:id)
        dispatched_packages_location.save
      end
    end
  end
end
