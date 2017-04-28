require "goodcity/rake_logger"
#rake goodcity:populate_packages_location_data
namespace :goodcity do
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    exclude_ids = PackagesLocation.pluck(:package_id)
    packages = Package.where("stockit_sent_on is null and inventory_number is not null").except_package(exclude_ids)

    # code to create log for the rake
    log = Goodcity::RakeLogger.new("populate_packages_location_data")
    log.log_info("\n#{'-'*75}")
    log.log_info("\nRunning rake task 'populate_packages_location_data'....")
    log.log_info("\nInitial values")
    log.log_info("\n\tNumber of Packages used to create PackagesLocation =#{packages.count}")
    log.log_info("\n\tNumber of PackagesLocation before rake =#{PackagesLocation.count}")
    log.log_info("\n\tFirst Package whose PackagesLocation will be created =#{packages.first.id}")
    log.log_info("\n\tLast Package whose PackagesLocation will be created =#{packages.last.id}")
    first_id = PackagesLocation.last.id + 1
    count = 0
    # end of code to create log for the rake
    packages.find_each do |package|
      PackagesLocation.create(
        location_id: package.location_id,
        package_id: package.id,
        quantity: package.received_quantity
        )
      count += 1
    end
    # code to create log for the rake
    log.log_info("\nUpdated values")
    log.log_info("\n\tNumber of OrdersPackage after rake =#{count}")
    log.log_info("\n\tFirst PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.where(id: first_id).pluck(:id, :package_id, :location_id)}")
    log.log_info("\n\tLast PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.pluck(:id, :package_id, :location_id).last}")
    log.close
    # end of code to create log for the rake
  end
end
