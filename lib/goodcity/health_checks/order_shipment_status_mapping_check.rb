require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrderShipmentStatusMappingCheck < Base
      desc "Orders should map their shipment status to Goodcity state."
      def run
        ids = []
        Order::SHIPMENT_STATUS_MAP.each do |status, state|
          ids << Order.shipments.select(:id).where(status: status).where('state != ?', state).pluck(:id)
        end
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity Orders with shipment status should map to specific state. Run 'rake orders:map_shipment_status' to remediate. (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
