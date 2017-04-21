#rake goodcity:populate_packages_location_data

namespace :goodcity do
  desc 'populate packages_location with existing packages data'
  task populate_packages_location_data: :environment do
    exclude_ids = PackagesLocation.pluck(:package_id)
    packages = Package.where("stockit_sent_on is null and inventory_number is not null").except_package(exclude_ids)

    # code to create log for the rake
    x = Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\n#{'-'*80}"
      f << "\nRunning rake task 'populate_packages_location_data'...."
      f << "\nCurrent time: #{x}"
      f << "\nInitial values"
      f << "\n\tNumber of Packages used to create PackagesLocation =#{packages.count}"
      f << "\n\tNumber of PackagesLocation before rake =#{PackagesLocation.count}"
      f << "\n\tFirst Package whose PackagesLocation will be created =#{packages.first}"
      f << "\n\tLast Package whose PackagesLocation will be created =#{packages.last}"
    }
    first_id = PackagesLocation.last.id+1
    # end of code to create log for the rake

    packages.find_each do |package|
      PackagesLocation.create(
        location_id: package.location_id,
        package_id: package.id,
        quantity: package.received_quantity
        )
    end

    # code to create log for the rake
    y=Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\nTotal time taken: #{x-y} seconds"
      f << "\nUpdated values"
      f << "\n\tNumber of OrdersPackage after rake =#{PackagesLocation.count}"
      f << "\n\tFirst PackagesLocation created =#{PackagesLocation.find(first_id)}"
      f << "\n\tLast PackagesLocation created =#{PackagesLocation.last}"
    }

    # end of code to create log for the rake
  end
end
