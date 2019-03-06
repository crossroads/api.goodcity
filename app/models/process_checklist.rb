class ProcessChecklist < ActiveRecord::Base
  translates :text
  belongs_to :booking_type
  has_many :orders

  def self.for_booking_type(bt)
    where({ booking_type: bt })
  end
end
