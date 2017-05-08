require "goodcity/rake_logger"
#rake goodcity:populate_packages_location_data
namespace :goodcity do
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    exclude_ids = PackagesLocation.pluck(:package_id)
    packages = Package.where("inventory_number is not null").except_package(exclude_ids)
    # code to create log for the rake
    log = Goodcity::RakeLogger.new("populate_packages_location_data")
    log.info("\n\tInitial Number of Packages used to create PackagesLocation =#{packages.count}")
    log.info("\n\tInitial Number of PackagesLocation before rake =#{PackagesLocation.count}")
    log.debug("\n\tInitial First Package whose PackagesLocation will be created =#{packages.first.id}")
    log.debug("\n\tInitial Last Package whose PackagesLocation will be created =#{packages.last.id}")
    count = 0
    # end of code to create log for the rake
    packages.find_each do |package|
      if(location_id = package.location_id.presence)
        PackagesLocation.create(
          location_id: location_id,
          package_id: package.id,
          quantity: package.received_quantity
          )
        count += 1
      end
    end
    # code to create log for the rake
    log.info("\n\tUpdated Number of OrdersPackage after rake =#{count}")
    log.debug("\n\tUpdated First PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.pluck(:id, :package_id, :location_id).first}")
    log.debug("\n\tUpdated Last PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.pluck(:id, :package_id, :location_id).last}")
    log.close
    # end of code to create log for the rake
  end
end
