class Schedule < ActiveRecord::Base
  has_many :deliveries, inverse_of: :schedule

  def formatted_date_and_slot
    "#{slot_name},
    #{scheduled_at.strftime("%a #{scheduled_at.day.ordinalize}")}"
  end
end
