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
    if eql?(PackagesInventory)
      # --- Adds a hook to the PackagesInventory model

      def related_packages_location
        PackagesLocation
          .where(package: package, location: location)
          .first_or_initialize(quantity: 0)
      end

      def update_packages_locations
        related_packages_location.sneaky do |record|
          record.quantity += quantity
          if record.quantity.positive?
            record.save
          elsif record.persisted?
            record.destroy
          end
        end
      end

      managed_hook :create, :after, :update_packages_locations
    end

    if eql?(PackagesLocation)
      # --- Adds hooks to the PackagesLocation model

      def inventorize_creation
        record_inventory_change(quantity, package_id, location_id)
      end

      def inventorize_update
        if package_id_changed? || location_id_changed?
          # 1. We negate the entire previous quantity
          record_inventory_change(- quantity_was, package_id_was, location_id_was)
          # 2. We record from scratch with the new infos
          record_inventory_change(quantity, package_id, location_id)
        else
          # We just record the change in quantity
          record_inventory_change(quantity - quantity_was, package_id, location_id)
        end
      end

      def inventorize_deletion
        record_inventory_change(-1 * quantity, package_id, location_id)
      end

      managed_hook :create,  :after,  :inventorize_creation
      managed_hook :update,  :after,  :inventorize_update
      managed_hook :destroy, :after,  :inventorize_deletion

      # --- Sync helpers

      def record_inventory_author
        User.current_user || User.system_user
      end

      def record_inventory_action(quantity_diff)
        return PackagesInventory::Actions::LOSS if quantity_diff.negative?
        PackagesInventory::Actions::GAIN
      end

      def record_inventory_change(quantity_diff, pkg_id, loc_id)
        return if quantity_diff.zero?

        PackagesInventory.new(
          action:       record_inventory_action(quantity_diff),
          user:         record_inventory_author,
          package_id:   pkg_id,
          location_id:  loc_id,
          quantity:     quantity_diff
        ).sneaky(:save)
      end
    end
  end
end
