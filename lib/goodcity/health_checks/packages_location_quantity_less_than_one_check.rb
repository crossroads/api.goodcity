# -- test for qty < 1
# SELECT packages_locations.*, packages.received_quantity aS pkg_qty from packages_locations
# JOIN packages ON packages.id = packages_locations.package_id
# WHERE packages_locations.quantity < 1
 
# -- remediation
# UPDATE packages_locations
# SET quantity = packages.received_quantity
# FROM packages
# WHERE packages_locations.quantity < 1

require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackagesLocationQuantityLessThanOneCheck < Base
      desc "PackagesLocations should not have quantity less than 1."
      def run
        ids = PackagesLocation.where('quantity < 1').pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity PackagesLocations with quantity less than 1 (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
