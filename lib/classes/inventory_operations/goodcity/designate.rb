module InventoryOperations
  module Goodcity
    class Designate < Base
      def initialize(package_id, order_id, quantity)
        super
      end

      def designate
        if orders_package.persisted?
          designate_to_existing_designation
        else
          new_designation
        end
      end

      def new_designation
        orders_package            = OrdersPackage.new
        orders_package.order_id   = order_id
        orders_package.package_id = package_id
        orders_package.quantity   = quantity
        orders_package.state      = 'designated'
        orders_package.updated_by = current_user
        orders_package.save
      end

      def designate_to_existing_designation
        if orders_package
          assign_total_quantity_to_designate
          perform_dependant_operations_based_on_state
          orders_package.save
        end
      end

      def perform_dependant_operations_based_on_state
        case orders_package.state
        when 'cancelled'
          orders_package.state = 'designated'
        when 'dispatched'
          manage_dispatched_location
        end
      end

      def manage_dispatched_location
        if total_quantity_designation?
          package.dispatched_packages_location.quantity = total_quantity
          package.dispatched_packages_location.save
          package.destroy_other_locations(dispatched_location_id)
        end
      end

      def total_quantity_designation?
        total_quantity == package.received_quantity
      end

      def dispatched_location_id
        @dispatched_location_id ||= Location.dispatch_location.id
      end

      def assign_total_quantity_to_designate
        total_quantity = orders_package.quantity + quantity
        orders_package.quantity = total_quantity
      end
    end
  end
end
