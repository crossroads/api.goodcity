
class BookingType < ApplicationRecord
  has_many :orders

  validates_uniqueness_of :name_en, :name_zh_tw

  def appointment?
    identifier == "appointment"
  end

  def online_order?
    identifier == "online-order"
  end

  def self.appointment
    BookingType.find_by(identifier: "appointment")
  end

  def self.online_order
    BookingType.find_by(identifier: "online-order")
  end
end
