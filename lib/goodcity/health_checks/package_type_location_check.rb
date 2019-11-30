require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackageTypeLocationCheck < Base
      desc "PackageType should have a valid location."
      def run
        ids = PackageType.where("location_id IS NULL").pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity PackageTypes with no default location. (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
