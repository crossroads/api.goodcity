require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageNotDispatchedByStockitSentOnSetCheck < Base
      desc "Orders Packages state not dispatched but packages.stockit_sent_on is set"
      def run
        ids = OrdersPackage.joins(:package).where("packages.stockit_sent_on IS NOT NULL and orders_packages.state NOT IN ('dispatched', 'cancelled', 'requested')").select(:id).pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity OrdersPackages where state is not dispatched but packages.stockit_sent_on is set. orders_packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
