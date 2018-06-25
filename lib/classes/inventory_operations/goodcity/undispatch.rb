module InventoryOperations
  module Goodcity
    class Undispatch < Base
      attr_accessor :location_id, :referenced_packages_location, :packages_location

      def initialize(options = {})
        super
        self.location_id = options[:location_id]
        self.referenced_packages_location = package.referenced_packages_location(orders_package.id)
        self.packages_location = packages_location_to_modify
      end

      def undispatch
        orders_package.undispatch
        move_quatity_to_location
      end

      def existing_packages_location_record_with_same_id
        @existing_record ||= package.find_packages_location_with_location_id(location_id)
      end

      def move_quatity_to_location
        if quantity == package.received_quantity
          packages_location.reference_to_orders_package = nil
          destroy_other_locations
        end
        assign_values_and_save_packages_location
      end

      def destroy_other_locations
        package.packages_locations.where.not(location_id: packages_location.location_id).destroy_all
      end

      def assign_values_and_save_packages_location
        packages_location.quantity += quantity
        packages_location.location_id = location_id
        packages_location.save
      end

      def packages_location_to_modify
        @packages_location ||= existing_packages_location_record_with_same_id || referenced_packages_location || package.packages_locations.first
      end

      # def move_quantity_to_location
      #   if existing_packages_location_record_with_same_id
      #     packages_location_with_same_location.quantity += orders_package.quanity
      #     packages_location_with_same_location.reference_to_orders_package = nil
      #     referenced_packages_location.destroy
      #   elsif referenced_packages_location
      #     referenced_packages_location.quanity += orders_package.quanity
      #     referenced_packages_location.location_id = location_id
      #   else
      #     packages_location = package.packages_location.first
      #     packages_location.quanity += orders_package.quanity
      #     packages_location.location_id = location_id
      #   end
      # end
    end
  end
end
