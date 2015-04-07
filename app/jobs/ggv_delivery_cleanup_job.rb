class GgvDeliveryCleanupJob < ActiveJob::Base
  queue_as :gogovan_orders

  def perform(order_id)
    order = GogovanOrder.find_by(id: order_id)
    offer = order.try(:delivery).try(:offer)
    offer.try(:send_ggv_cancel_order_message)
    order.try(:delivery).try(:destroy)
  end
end
