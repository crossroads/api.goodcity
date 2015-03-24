class PollGogovanOrderStatusJob < ActiveJob::Base
  queue_as :gogovan_orders

  def perform(order_id)
    order = GogovanOrder.find_by(id: order_id)
    if order
      order_details = Gogovan.new().get_status(order.booking_id)

      unless order_details[:error]
        order = order.assign_details(order_details)
        order.save if order.changed? # to avoid un-necessary push-updates to api
      end

      puts "GGV Order #{order.id} updated."

      self.class.set(wait: GGV_POLL_JOB_WAIT_TIME).perform_later(order_id) if order.reload.need_polling?
    end
  end
end
