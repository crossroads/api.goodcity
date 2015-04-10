class PollGogovanOrderStatusJob < ActiveJob::Base
  queue_as :gogovan_orders

  def perform(order_id)
    order = GogovanOrder.find_by(id: order_id)
    if order.try(:delivery)
      Rails.logger.info "Updating GGV Order #{order_id}"
      order_details = Gogovan.new.get_status(order.booking_id)

      unless order_details[:error]
        order = order.assign_details(order_details)
        return remove_delivery(order_id) if order.cancelled?

        order.save if order.changed? # avoid un-necessary push-updates to api
        schedule_polling(order_id) if order.reload.need_polling?
      end
    else
      order.try(:destroy)
    end
  end

  def remove_delivery(order_id)
    GgvDeliveryCleanupJob.set(wait: GGV_POLL_JOB_WAIT_TIME).
      perform_later(order_id)
  end

  def schedule_polling(order_id)
    self.class.set(wait: GGV_POLL_JOB_WAIT_TIME).perform_later(order_id)
  end
end
