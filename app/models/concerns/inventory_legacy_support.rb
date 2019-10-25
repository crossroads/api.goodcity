##
# Syncing of two tables: PackagesInventory <--> PackagesLocation
#
# Adds hooks to the PackagesLocation model
#   - after_create: Add a record to inventory_packages which adds that quantity to the package
#   - after_destroy: Add a record to the inventory_packages that negates the quantity that used to exist in packages_locations
#   - after_update: Add a record to the inventory_packages which adds the \
#       difference of quantity that was applied to the record (quantity - quantity_was)
#
# Adds a hook to the PackagesInventory model
#   - after_create: For the given package/location combination, compute the quantity and create a packages_locations row to represent it.
#       If it already exists then update it
#
#
module InventoryLegacySupport
  extend ActiveSupport::Concern

  include HookControls

  included do

    if self.eql?(PackagesInventory)
      # --- Adds a hook to the PackagesInventory model

      def update_packages_locations
        pkg_loc = PackagesLocation.find_by(package: package, location: location)
        pkg_loc = PackagesLocation.new(quantity: 0, package: package, location: location) if pkg_loc.nil?
        pkg_loc.sneaky(:increment!, :quantity, quantity)
      end

      managed_hook :create, :after, :update_packages_locations
    end

    if self.eql?(PackagesLocation)
      # --- Adds hooks to the PackagesLocation model

      def inventorize_creation
        update_inventory!(quantity)
      end

      def inventorize_update
        update_inventory!(quantity - quantity_was)
      end

      def inventorize_deletion
        update_inventory!(-1 * quantity)
      end

      managed_hook :create,  :after,  :inventorize_creation
      managed_hook :update,  :after,  :inventorize_update
      managed_hook :destroy, :after,  :inventorize_deletion

      # --- Sync helpers

      def update_inventory!(quantity_change)
        return if quantity_change.zero?

        action = quantity_change.negative? ?
          PackagesInventory::Actions::LOSS :
          PackagesInventory::Actions::GAIN

        PackagesInventory.new(
          action:   action,
          user:     User.current_user,
          package:  package,
          location: location,
          quantity: quantity_change
        ).sneaky(:save)
      end
    end
  end
end
