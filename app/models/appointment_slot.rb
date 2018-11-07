class AppointmentSlot < ActiveRecord::Base
  validates :quota, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.calendar(from, to)
    (from..to).map { |date| { date: date, slots: AppointmentSlot.for_date(date) } }
  end

  scope :upcoming, -> { where("timestamp >= ?", DateTime.now.beginning_of_day.to_s(:db)) }

  scope :ascending, -> { order('timestamp ASC').order('quota ASC') }

  def self.for_date(date)
    slots = where("date(timestamp) = ?", date).ascending
    return slots.select { |sl| 
      sl.timestamp = sl.timestamp.in_time_zone
      sl.quota.positive? 
    } unless slots.empty?

    # Generate slots based on preset if no special slot have been specified for that date
    AppointmentSlotPreset
      .where(day: date.wday)
      .ascending
      .map { |preset|
        t = date.to_datetime.in_time_zone.change(hour: preset.hours, min: preset.minutes, sec: 0)
        AppointmentSlot.new(quota: preset.quota, timestamp: t)
      }
  end
end
