#rake goodcity:populate_packages_location_data
namespace :goodcity do
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    exclude_ids = PackagesLocation.pluck(:package_id)
    packages = Package.where("stockit_sent_on is null and inventory_number is not null").except_package(exclude_ids)

    # code to create log for the rake
    start_time = Time.now
    rake_logger = Logger.new("#{Rails.root}/log/rake_log.log")
    log = ("\n#{'-'*75}")
    rake_logger.info(log)
    log += ("\nRunning rake task 'populate_packages_location_data'....")
    log += ("\nCurrent time: #{start_time}")
    log += ("\nInitial values")
    log += ("\n\tNumber of Packages used to create PackagesLocation =#{packages.count}")
    log += ("\n\tNumber of PackagesLocation before rake =#{PackagesLocation.count}")
    log += ("\n\tFirst Package whose PackagesLocation will be created =#{packages.first.id}")
    log += ("\n\tLast Package whose PackagesLocation will be created =#{packages.last.id}")
    rake_logger.info(log)
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
    end_time = Time.now
    log = ("\nTotal time taken: #{end_time-start_time} seconds")
    log += ("\nUpdated values")
    log += ("\n\tNumber of OrdersPackage after rake =#{count}")
    log += ("\n\tFirst PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.where(id: first_id).pluck(:id, :package_id, :location_id)}")
    log += ("\n\tLast PackagesLocation (:id, :package_id, :location_id) created =#{PackagesLocation.pluck(:id, :package_id, :location_id).last}")
    rake_logger.info(log)
    rake_logger.close
    # end of code to create log for the rake
  end
end
