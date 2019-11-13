require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageDesignatedButSentCheck < Base
      desc "Orders Packages should not be in state designated and have a sent_on date"
      def run
        ids = OrdersPackage.select(:id).where("sent_on IS NOT NULL AND state NOT IN ('dispatched', 'cancelled', 'requested')").pluck(:id)
        if ids.size == 0
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages that should be dispatched. orders_packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
