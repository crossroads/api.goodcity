# rake goodcity:copy_booking_type
namespace :goodcity do
  task copy_booking_type: :environment do
    i = 0
    log = Goodcity::RakeLogger.new("copy_booking_type")
    order_transports = OrderTransport.where("booking_type_id is not null")
    log.info(": #{order_transports.count} orderTransports found")
    order_transports.each do |order_transport|
      order = Order.find_by_id(order_transport.order_id)
      if order
        order.update(booking_type_id: order_transport.booking_type_id)
        i += 1
      end
    end
    log.info(": #{i} orders updated")
  end
end
