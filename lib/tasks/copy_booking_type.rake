# rake goodcity:copy_booking_type
namespace :goodcity do
  task copy_booking_type: :environment do
    OrderTransport.where("booking_type_id is not null").each do |ot|
      order = Order.find_by_id(ot.order_id)
      order.update(booking_type_id: ot.booking_type_id) if order
    end
  end
end
