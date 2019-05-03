# rake goodcity:update_received_quantity_to_package
namespace :goodcity do
  desc 'Update received quantities to package'
  task update_received_quantity_to_package: :environment do
    counter = 0
    quantity_packages = Package.where("packages.received_quantity > 1")
    quantity_packages.each do |package|
      all_packages = Package.where("packages.inventory_number LIKE ?",
        "#{package.inventory_number}%")
      child_packages = all_packages - [package] if all_packages.count > 1
      child_packages.any? && package.update(received_quantity: package.quantity) && counter+=1
    end
    puts "#{count} packages updated"
  end
end
