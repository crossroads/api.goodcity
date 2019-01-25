#rake goodcity:assign_online_order_booking_type_to_goodcity_orders
require "goodcity/rake_logger"

namespace :goodcity do 
  task assign_online_order_booking_type_to_goodcity_orders: :environment  do
    log = Goodcity::RakeLogger.new("assign_online_order_booking_type_to_goodcity_orders")
    online_order_booking_type_id = BookingType.online_order.id

    count = 0

    begin
      OrderTransport.joins(:order).where('orders.detail_type = (?) and order_transports.booking_type_id IS null', 
        'GoodCity').find_each do |order_transport|
        order_transport.booking_type_id = online_order_booking_type_id
        if order_transport.save
          count += 1
        else
          log.error "OrderTransport with Id #{order_transport.id} didn't save error: #{order_transport.errors.full_messages}"
        end
      end
    rescue => e 
      log.error "(#{e.message})"
    end

    log.info(": #{count} records updated")
    log.close
  end
end