module InventoryInitializer
  def initialize_inventory(*packages, location: nil)
    location ||= pkg.locations.first || FactoryBot.create(:location)
    [packages].flatten.each do |pkg|
      return if PackagesInventory.where(package: pkg).count.positive? # Already initialized
      create :packages_inventory, package: pkg, quantity: pkg.received_quantity, action: 'inventory', location: location

      pkg.orders_packages.dispatched.each do |orders_package|
        create :packages_inventory, package: pkg, quantity: - orders_package.quantity, action: 'dispatch', location: location
      end

      pkg.requested_packages.each(&:update_availability!)
    end
  end
end