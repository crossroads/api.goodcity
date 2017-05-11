require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class ReceivedPackagesLocationIdCheck < Base
      desc "Received Packages should contain location_id reference."
      def run
        ids = Package.where('inventory_number is not null and location_id is null').pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity received Packages with nil location_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
