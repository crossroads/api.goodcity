require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class OrdersPackagesOrderIdCheck < Base
      desc "OrdersPackages should contain an order_id reference."
      def run
        ids = OrdersPackage.where(order_id: nil).pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages with nil order_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
