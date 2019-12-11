module InventoryInitializer
  def initialize_inventory(packages)
    [packages].flatten.each do |pkg|
      return if PackagesInventory.where(package: pkg).count.positive? # Already initialized
      create :packages_inventory, package: pkg, quantity: pkg.received_quantity, action: 'inventory'
      pkg.requested_packages.each(&:update_availability!)
    end
  end
end