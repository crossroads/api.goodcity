module InventoryOperations
  module Goodcity
    class Move < Base
      attr_accessor :quantity_and_location_mapping, :packages_location, :location_id

      def initialize(options = {})
        super
        self.quantity_and_location_mapping = options[:quantity_and_location_mapping]
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
        packages_location = package.packages_locations.first
        packages_location.quantity = quantity
        packages_location.location_id = location_id
        packages_location.save
        # package.update_singletone_packages_location(location_id, quantity)
      end

      def move_multi_quantity_package
        package.deduct_quantity_from_packages_locations(quantity_and_location_mapping)
        update_or_create_packages_location
      end

      def update_or_create_packages_location
        if packages_location = packages_location_exists?
          packages_location.quantity += quantity
          packages_location.save
        else
          package.packages_locations.create(
            location_id: location_id,
            quantity: quantity
          )
        end
      end

      def packages_location_exists?
        package.packages_locations.find_by_location_id(location_id)
      end
    end
  end
end
