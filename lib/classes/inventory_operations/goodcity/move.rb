module InventoryOperations
  module Goodcity
    class Move < Base
      attr_accessor :quantity_to_deduct_and_location_mapping, :packages_location_to_update, :location_id

      def initialize(options = {})
        super
        self.quantity_to_deduct_and_location_mapping = options[:quantity_to_deduct_and_location_mapping]
        self.location_id = options[:location_id]
      end

      def move
        if is_singletone_package
          move_singletone_package
        else
          move_multi_quantity_package
        end
      end

      def move_singletone_package
        package.update_singletone_packages_location
      end

      def move_multi_quantity_package
        package.deduct_quantity_from_packages_locations(quantity_to_deduct_and_location_mapping)
        package.update_or_create_qty_moved_to_location(location_id, total_qty)
      end
    end
  end
end
