require 'goodcity/health_checks/base'

# SELECT * FROM orders_packages
# WHERE sent_on IS NULL AND state = 'dispatched'

module Goodcity
  class HealthChecks
    class OrdersPackageStateDispatchedSentOnNilCheck < Base
      desc "OrdersPackages in state 'dispatched' should have a sent_on date"
      def run
        ids = OrdersPackage.where(sent_on: nil).where(state: 'dispatched').pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages in state 'dispatched' but sent_on date is not set. orders_packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
