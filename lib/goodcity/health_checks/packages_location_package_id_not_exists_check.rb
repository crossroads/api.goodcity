# SELECT packages_location.*
# FROM packages_location
# WHERE package_id IN (
#   SELECT package_id FROM packages_location
#   EXCEPT SELECT id FROM packages
# )
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackagesLocationPackageIdNotExistsCheck < Base
      desc "PackagesLocation package_id should exist in packages."
      def run
        ids = PackagesLocation.
          where('package_id IN (SELECT package_id FROM packages_locations EXCEPT SELECT id FROM packages)').
          pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity PackagesLocation package_id doesn't exist in packages table. packages_location.package_id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
