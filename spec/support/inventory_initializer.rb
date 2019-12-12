module InventoryInitializer
  def initialize_inventory(*packages)
    [packages].flatten.each do |pkg|
      return if PackagesInventory.where(package: pkg).count.positive? # Already initialized
      create :packages_inventory, package: pkg, quantity: pkg.received_quantity, action: 'inventory'

      pkg.orders_packages.dispatched.each do |orders_package|
        create :packages_inventory, package: pkg, quantity: - orders_package.quantity, action: 'dispatch', location: pkg.locations.first
      end

      pkg.requested_packages.each(&:update_availability!)
    end
  end
end