require 'goodcity/health_checks/base'

# This only makes sense whilst partial designate/dispatch is turned off.

module Goodcity
  class HealthChecks
    class OrdersPackagePartialQuantityNotAllowedCheck < Base
      desc "OrdersPackages should be fully dispatched or designated"
      def run
        ids = OrdersPackage.joins(:package).where("orders_packages.quantity != packages.received_quantity").where("orders_packages.state != 'cancelled'").pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages partially designated/dispatched. orders_packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
