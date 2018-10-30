class AppointmentSlot < ActiveRecord::Base
  validates :quota, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.for_date(date)
    slots = where("date(timestamp) = ?", date).ascending
    unless slots.empty?
      slots.each {|s| s.timestamp = s.timestamp.in_time_zone}
      return slots
    end

    # Generate slots based on preset if no special slot have been specified for that date
    AppointmentSlotPreset
      .where(day: date.wday)
      .ascending
      .map {|preset| 
        t = date.to_datetime.in_time_zone.change(hour: preset.hours, min: preset.minutes, sec: 0)
        AppointmentSlot.new(quota: preset.quota, timestamp: t)
      }
  end

  def self.calendar(from, to)
    (from..to).map { |date| { date: date, slots: AppointmentSlot.for_date(date) } }
  end

  scope :upcoming, -> { where("timestamp >= ?", DateTime.now.beginning_of_day.to_s(:db)) }

  scope :ascending, -> { order('timestamp ASC') }

end