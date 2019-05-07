module GoodCity
  class UpdatePackageReceivedQuantity
    def self.run!
      counter = 0
      log = Goodcity::RakeLogger.new("update_received_quantity_to_package")
      Package.where("packages.received_quantity > 1").find_each do |package|
        child_packages_present?(package) && package.update(received_quantity: package.quantity) && counter+=1
      end
      puts "#{counter} packages updated"
      log.info(": #{counter} packages updated")
    end

    def self.child_packages_present?(package)
      all_packages = Package.where("packages.inventory_number LIKE ?",
        "#{package.inventory_number}%")
      child_packages = (all_packages - [package]).present? if all_packages.count > 1
    end
  end
end
