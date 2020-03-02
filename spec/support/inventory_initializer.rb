module InventoryInitializer
  def initialize_inventory(*packages, location: nil)
    [packages].flatten.each do |pkg|
      return if PackagesInventory.where(package: pkg).count.positive? # Already initialized

      dest_location = location || pkg.locations.first || FactoryBot.create(:location)

      create :packages_inventory, package: pkg, quantity: pkg.received_quantity, action: 'inventory', location: dest_location

      pkg.orders_packages.dispatched.each do |orders_package|
        create :packages_inventory, package: pkg, quantity: - orders_package.quantity, action: 'dispatch', location: dest_location
      end

      pkg.requested_packages.each(&:update_availability!)
    end
  end
end