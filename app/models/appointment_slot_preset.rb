class AppointmentSlotPreset < ActiveRecord::Base
  validates :day, numericality: { only_integer: true, greater_than: 0, less_than: 8  }
  validates :hours, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 24 }
  validates :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 60 }
  validates :quota, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :ascending, -> { order('hours ASC').order('minutes ASC') }
end
