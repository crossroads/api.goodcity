class AppointmentSlot < ActiveRecord::Base
  validates :quota, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :no_duplicate, on: [:create, :update]
  before_save :truncate_seconds

  scope :upcoming, -> { where("timestamp >= ?", DateTime.now.beginning_of_day.utc.to_s(:db)) }

  scope :ascending, -> { order('timestamp ASC').order('quota ASC') }

  def self.appointments_booked_for_slot(slot)
    appointment_type = BookingType.appointment.id
    time_string = slot.timestamp.in_time_zone
      .strftime("%I:%M %p")
      .tr(' ', '')
      .sub(':00', '')
      .sub(/^[0]*/, '')
    
    OrderTransport
      .where("booking_type_id = :appointment_type AND scheduled_at = :date AND timeslot ILIKE :time", 
        date: slot.timestamp.to_date, 
        appointment_type: appointment_type,
        time: "#{time_string}%")
  end

  def self.wrap_slot(slot)
    appointments_booked = appointments_booked_for_slot(slot).count
    val = slot.as_json
    val['isClosed'] = appointments_booked >= slot.quota
    val['remaining'] = (slot.quota - appointments_booked).clamp(0, slot.quota)
    val
  end

  def self.calendar(from, to)
    (from..to).map { |date|
      item = Hash.new
      item["date"] = date
      item["slots"] = AppointmentSlot.for_date(date).map(&method(:wrap_slot))
      item["isClosed"] = item["slots"].find { |s| not s['isClosed'] }.nil?
      item
    }
  end

  def self.for_date(date)
    slots = where("date(timestamp) = ?", date).ascending
    return slots.select { |sl| 
      sl.timestamp = sl.timestamp.in_time_zone
      sl.quota.positive? 
    } unless slots.empty?

    return [] if Holiday.is_holiday(date)

    # Generate slots based on preset if no special slot have been specified for that date
    AppointmentSlotPreset
      .where(day: date.wday)
      .ascending
      .map { |preset|
        t = date.to_datetime.in_time_zone.change(hour: preset.hours, min: preset.minutes, sec: 0)
        AppointmentSlot.new(quota: preset.quota, timestamp: t)
      }
  end

  # Validators and Hooks

  def truncate_seconds
    self.timestamp = self.timestamp.change(sec: 0)
  end

  def no_duplicate
    return if quota.zero?
    records = AppointmentSlot
      .where(timestamp: self.timestamp)
      .where
      .not(quota: 0)
    records = records.where.not(id: self.id) unless self.new_record?
    errors.add(:errors, "Timeslot already exists") unless records.empty?
  end

end
