namespace :goodcity do

  #rake goodcity:populate_packages_location_data
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    Package.where("stockit_sent_on is null and inventory_number is not null").find_each do |package|
      PackagesLocation.create(
        location_id: package.location_id,
        package_id: package.id,
        quantity: package.received_quantity
        )
    end
  end
end
