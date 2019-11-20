# Find all duplicate package_id, location_id
#
# WITH pls AS (
#     select packages_locations.*, COUNT(id) OVER (PARTITION BY package_id, location_id) AS count
#     FROM packages_locations
# )
# SELECT * from pls WHERE count > 1 ORDER BY location_id, package_id, id;
#
# Delete duplicates (keeping the lowest id)
#
# DELETE FROM packages_locations a
# USING packages_locations b
# WHERE
#     a.id > b.id
#     AND a.package_id = b.package_id
#     AND a.location_id = b.location_id;
#
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackagesLocationDuplicatesCheck < Base
      desc "PackagesLocations should not contain duplicate package_id and location_id references."
      def run
        ids = PackagesLocation.select([:package_id, :location_id]).
          group([:package_id, :location_id]).
          having('COUNT(*) > 1').
          pluck(:package_id, :location_id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity PackagesLocations with duplicate package_id and location_id (#{ids.size}): #{ids.map{|p,o| "package_id: #{p}, location_id: #{o}"}.join('; ')}")
        end
      end
    end
  end
end
