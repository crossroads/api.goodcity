
class BookingType < ApplicationRecord
  has_many :orders
  
  validates :identifier, :name_en, :name_zh_tw, uniqueness: true

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
