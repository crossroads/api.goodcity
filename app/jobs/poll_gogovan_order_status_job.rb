class PollGogovanOrderStatusJob < ActiveJob::Base
  queue_as :gogovan_orders

  def perform(order)
    order_details = Gogovan.new().get_status(order.booking_id)

    unless order_details[:error]
      order.status = order_details["status"]
      order.price = order_details["price"]
      if (driver_details = order_details["driver"])
        order.driver_name = driver_details["name"]
        order.driver_mobile = driver_details["phone_number"]
        order.driver_license = driver_details["license_plate"]
      end

      order.save if order.changed? # to avoid un-necessary push-updates to api
    end

    self.class.perform_later(wait: GGV_POLL_JOB_WAIT_TIME) if order.reload.need_polling?
  end
end
