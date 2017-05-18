require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class OrderStockitIdNilCheck < Base
      desc "Orders should contain a stockit_id reference."
      def run
        ids = Order.where(stockit_id: nil).pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity Orders with nil stockit_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
