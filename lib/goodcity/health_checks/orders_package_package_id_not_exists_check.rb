# SELECT orders_packages.*
# FROM orders_packages
# WHERE package_id IN (
#   SELECT package_id FROM orders_packages
#   EXCEPT SELECT id FROM packages
# )
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackagePackageIdNotExistsCheck < Base
      desc "OrdersPackages package_id should exist in packages."
      def run
        ids = OrdersPackage.
          where('package_id IN (SELECT package_id FROM orders_packages EXCEPT SELECT id FROM packages)').
          pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages package_id doesn't exist in packages table. orders_packages.package_id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
