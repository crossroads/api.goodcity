class Schedule < ActiveRecord::Base
  include PushUpdates

  has_many :deliveries

  def formatted_date_and_slot
    "#{slot_name},
    #{scheduled_at.strftime("%a #{scheduled_at.day.ordinalize}")}"
  end

  #required by PusherUpdates module
  def offer
    deliveries.last.try(:offer)
  end
end
