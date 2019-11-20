# SELECT orders_packages.*
# FROM orders_packages
# WHERE order_id IN (
#   SELECT order_id FROM orders_packages
#   EXCEPT SELECT id FROM orders
# )
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageOrderIdNotExistsCheck < Base
      desc "OrdersPackages order_id should exist in packages."
      def run
        ids = OrdersPackage.
          where('order_id IN (SELECT order_id FROM orders_packages EXCEPT SELECT id FROM orders)').
          pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages order_id doesn't exist in orders table. orders_packages.order_id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
