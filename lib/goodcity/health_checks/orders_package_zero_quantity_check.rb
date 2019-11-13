# SELEcT packages.inventory_number, packages.quantity, orders_packages.state, orders_packages.sent_on, packages.created_at FROM packages
# LEFT JOIN orders_packages ON orders_packages.package_id = packages.id
# WHERE orders_packages.state IN ('dispatched', 'designated', 'requested')
#   AND orders_packages.quantity = 0
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageZeroQuantityCheck < Base
      desc "OrdersPackages should not have quantity < 1"
      def run
        ids = OrdersPackage.where('quantity < 1').where('NOT state = \'cancelled\'').pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages should not have quantity < 1. orders_packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
