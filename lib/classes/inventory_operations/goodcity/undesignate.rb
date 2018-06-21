module InventoryOperations
  module Goodcity
    class Undesignate < Base
      def initialize(options = {})
        super
      end

      def undesignate
        remove_designation_of_associated_package
        assign_quantity_and_state
        orders_package.save
      end

      def remove_designation_of_associated_package
        if package.singleton_package?
          package.undesignate_from_stockit_order
        end
      end

      def calculated_quantity_of_orders_package
        orders_package.quantity - quantity
      end

      def assign_quantity_and_state
        if calculated_quantity_of_orders_package.zero?
          orders_package.state = 'cancelled'
        end
        orders_package.quantity = calculated_quantity_of_orders_package
      end
    end
  end
end
