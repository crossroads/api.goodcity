# SELECT packages_locations.*, packages.received_quantity aS pkg_qty from packages_locations
# JOIN packages ON packages.id = packages_locations.package_id
# WHERE packages_locations.quantity != packages.received_quantity
#
# REMEDIATION
#
# UPDATE packages_locations
# SET quantity = packages.received_quantity
# FROM packages
# WHERE packages_locations.package_id = packages.id
#   AND packages_locations.quantity != packages.received_quantity;
#
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackagesLocationQuantityNotEqualToPackagesCheck < Base
      desc "PackagesLocations should have equal quantity to packages (until we turn off Stockit)."
      def run
        ids = PackagesLocation.
          joins(:package).
          where('packages_locations.quantity != packages.received_quantity').pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity PackagesLocations with quantity not equal to package.received_quantity (until we turn off Stockit) (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
