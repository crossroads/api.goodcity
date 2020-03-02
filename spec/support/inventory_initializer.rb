module InventoryInitializer
  def initialize_inventory(*packages, location: nil)
    [packages].flatten.each do |pkg|
      return if PackagesInventory.where(package: pkg).count.positive? # Already initialized

      dest_location = location || pkg.locations.first || FactoryBot.create(:location)

      FactoryBot.create :packages_inventory, package: pkg, quantity: pkg.received_quantity, location: dest_location, action: 'inventory'

      pkg.orders_packages.dispatched.each do |orders_package|
        FactoryBot.create :packages_inventory, package: pkg, quantity: - orders_package.quantity, action: 'dispatch', location: dest_location, source: orders_package
      end

      pkg.requested_packages.each(&:update_availability!)
    end
  end

  module_function :initialize_inventory
end