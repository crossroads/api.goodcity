#rake goodcity:populate_packages_location_data

namespace :goodcity do
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    exclude_ids = PackagesLocation.pluck(:package_id)
    packages = Package.where("stockit_sent_on is null and inventory_number is not null").except_package(exclude_ids)
    packages.find_each do |package|
      PackagesLocation.create(
        location_id: package.location_id,
        package_id: package.id,
        quantity: package.received_quantity
        )
    end
  end
end
