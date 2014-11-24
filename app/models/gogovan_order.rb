class GogovanOrder < ActiveRecord::Base
  has_one :delivery

  def self.save_booking(booking_id)
    create(status: 'pending', booking_id: booking_id)
  end
end
