require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class DispatchedPackagesOrderIdCheck < Base
      desc "Dispatched packages should contain an order_id reference."
      def run
        ids = Package.where('stockit_sent_on is not null and order_id is null').pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity Dispatched Packages with nil sent_on or order_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
