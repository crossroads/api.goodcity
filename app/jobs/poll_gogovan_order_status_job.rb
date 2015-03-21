class PollGogovanOrderStatusJob < ActiveJob::Base
  queue_as :default

  def perform(order)
    order_details = Gogovan.new().get_status(order.booking_id)

    unless order_details[:error]
      order.price = order_details["price"]
      if (driver_details = order_details["driver"])
        order.driver_name = driver_details["name"]
        order.driver_mobile = driver_details["phone_number"]
        order.driver_license = driver_details["license_plate"]
      end
      order.save if order.changed? # to avoid un-necessary push-updates to api
    end

    self.class.perform_later(wait: 5.seconds) if order.reload.need_polling?
  end
end
