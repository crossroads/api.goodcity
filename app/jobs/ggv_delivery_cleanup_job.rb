class GgvDeliveryCleanupJob < ActiveJob::Base
  queue_as :gogovan_orders

  def perform(order_id)
    order = GogovanOrder.find_by(id: order_id)
    order.try(:delivery).try(:destroy)

    puts "\n\n\nDelivery for order #{order_id} deleted\n\n\n"
  end
end
