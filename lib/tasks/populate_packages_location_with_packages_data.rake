require "goodcity/rake_logger"

namespace :goodcity do
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    PaperTrail.enabled = false
    packages = Package.where("inventory_number is not null")
    bar = RakeProgressbar.new(packages.count)
    count = 0
    packages_location_package_ids = PackagesLocation.pluck("DISTINCT package_id")
    packages.select("id, location_id, received_quantity, state").find_each do |package|
      bar.inc
      next if packages_location_package_ids.include?(package.id)
      if(location_id = package.location_id.presence)
        PackagesLocation.create(
          location_id: location_id,
          package_id: package.id,
          quantity: package.received_quantity
          )
        count += 1
      end
    end
    bar.finished

    log = Goodcity::RakeLogger.new("populate_packages_location_data")
    log.info("\n\tUpdated Number of OrdersPackage after rake =#{count}")
    log.debug("\n\tUpdated First PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.pluck(:id, :package_id, :location_id).first}")
    log.debug("\n\tUpdated Last PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.pluck(:id, :package_id, :location_id).last}")
    log.close
  end
end
