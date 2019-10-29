require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class DispatchedPackagesOrderIdCheck < Goodcity::HealthChecks::Base
      desc "Dispatched packages should contain an order_id reference."
      def run
        ids = Package.where('stockit_sent_on IS NOT NULL AND order_id IS NULL').pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity Dispatched Packages with nil sent_on or order_id: #{ids.join(', ')}")
        end
      end
    end
  end
end
