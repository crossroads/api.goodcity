require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageDuplicatesCheck < Base
      desc "Orders Packages should not contain duplicate package_id and order_id references."
      def run
        ids = OrdersPackage.select([:package_id, :order_id]).group([:package_id, :order_id]).having('COUNT(*) > 1').pluck(:package_id, :order_id)
        if ids.size == 0
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages with duplicate package_id and order_id (#{ids.size}): #{ids.map{|p,o| "package_id: #{p}, order_id: #{o}"}.join('; ')}")
        end
      end
    end
  end
end
