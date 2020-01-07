# SELECT packages_locations.*
# FROM packages_locations
# WHERE location_id IN (
#   SELECT location_id FROM packages_locations
#   EXCEPT SELECT id FROM locations
# )
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackagesLocationLocationIdNotExistsCheck < Base
      desc "PackagesLocation location_id should exist in locations."
      def run
        ids = PackagesLocation.
          where('location_id IN (SELECT location_id FROM packages_locations EXCEPT SELECT id FROM locations)').
          pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity PackagesLocation location_id doesn't exist in locations table. packages_location.location_id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
