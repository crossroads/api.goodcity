require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackagesLocationDuplicateCheck < Base
      desc "There should be < 2 packages_location records per package"
      def run
        sql = 
          <<-SQL
          WITH packages_location_count AS (
            SELECT packages_locations.*, COUNT(id) OVER (PARTITION BY package_id) AS count
            FROM packages_locations
          )
          SELECT id from packages_location_count WHERE count > 1 ORDER BY package_id, id;
          SQL
        result = User.connection.execute(sql).map{|res| res['id']}.compact
        if result.empty?
          pass!
        else
          fail_with_message!("GoodCity Packages with more than one location (#{result.size}): #{result.join('; ')}")
        end
      end
    end
  end
end
