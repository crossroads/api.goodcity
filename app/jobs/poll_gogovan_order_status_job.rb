class PollGogovanOrderStatusJob < ActiveJob::Base
  queue_as :default

  def perform(order)
    order_details = Gogovan.new().get_status(order.booking_id)

    self.class.perform_later(wait: 5.seconds) if order.need_polling?
  end
end
