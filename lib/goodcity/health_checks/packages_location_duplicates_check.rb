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
        if ids.size == 0
          pass!
        else
          fail_with_message!("GoodCity PackagesLocations with duplicate package_id and location_id (#{ids.size}): #{ids.map{|p,o| "package_id: #{p}, location_id: #{o}"}.join('; ')}")
        end
      end
    end
  end
end
