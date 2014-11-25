class GogovanOrder < ActiveRecord::Base
  has_one :delivery

  def self.save_booking(booking_id)
    create(status: 'pending', booking_id: booking_id)
  end

  def self.place_order(user, attributes)
    Gogovan.new(user, attributes).get_order_price
  end

  def self.book_order(user, attributes)
    book_order = Gogovan.new(user, attributes).confirm_order
    save_booking(book_order['id'])
  end
end
