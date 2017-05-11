require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class LocationStockitIdNilCheck < Base
      desc "Locations should contain a stockit_id reference."
      def run
        ids = Location.where(stockit_id: nil).pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity Locations with nil stockit_id: #{ids.join(', ')}")
        end        
      end
    end

  end
end
