require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageOrderIdCheck < Base
      desc "OrdersPackages should contain an order_id reference."
      def run
        ids = OrdersPackage.where(order_id: nil).pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages with nil order_id. orders_packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
