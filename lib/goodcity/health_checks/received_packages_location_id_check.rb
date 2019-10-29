require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class ReceivedPackagesLocationIdCheck < Base
      desc "Received Packages should contain location_id reference."
      def run
        ids = Package.where('inventory_number IS NOT NULL AND location_id IS NULL').pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity received Packages with nil location_id: #{ids.join(', ')}")
        end
      end
    end
  end
end
