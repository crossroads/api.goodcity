
class BookingType < ActiveRecord::Base
  has_many :order_transports
  has_many :orders

  def self.appointment
    BookingType.find_by(identifier: "appointment")
  end

  def self.online_order
    BookingType.find_by(identifier: "online-order")
  end
end
