class GgvDeliveryCleanupJob < ActiveJob::Base
  queue_as :gogovan_orders

  def perform(order_id)
    order    = GogovanOrder.find_by(id: order_id)
    delivery = order.try(:delivery)
    offer    = delivery.try(:offer)
    ggv_time = delivery.try(:schedule).try(:formatted_date_and_slot)
    delivery.try(:destroy)
    offer.try(:send_ggv_cancel_order_message, ggv_time)
  end
end
