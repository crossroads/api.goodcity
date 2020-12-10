##
# Syncing of two tables: PackagesInventory <--> PackagesLocation
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

      def packages_location
        PackagesLocation
          .where(package: package, location: location)
          .first_or_initialize(quantity: 0)
      end

      def sync_packages_locations
        PackagesLocation.secured_transaction('sync:packages_locations') do
          packages_location.sneaky do |record|
            record.quantity = quantity + PackagesInventory::Computer.package_quantity(package, location: location)
            if record.quantity.positive?
              record.save
            elsif record.persisted?
              record.destroy
            end
          end
        end
      end

      managed_hook :create, :before, :sync_packages_locations
    end
  end
end
