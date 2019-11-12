module Goodcity
  module Cleanup
    module_function

    def delete_dispatched_packages_locations
      location_id = Location.dispatch_location.id
      PackagesLocation
        .joins("LEFT OUTER JOIN packages ON packages_locations.package_id = packages.id")
        .where(location_id: location_id)
        .where(
          <<-SQL
            packages.stockit_sent_on IS NOT NULL
              OR
            EXISTS(
              SELECT 1 FROM orders_packages WHERE (
                orders_packages.state = 'dispatched' AND
                orders_packages.package_id = packages_locations.package_id
              )
            )
          SQL
        )
        .delete_all
    end
  end
end
