require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrderDetailTypeNilCheck < Base
      desc "Orders should contain a stockit_id reference."
      def run
        ids = Order.where(detail_type: nil).pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity Orders with nil detail_type. orders.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
