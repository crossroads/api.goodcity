class AppointmentSlotPreset < ApplicationRecord
  include PushUpdatesMinimal

  validate :no_conflict, on: :update

  validates :day, numericality: { only_integer: true, greater_than: 0, less_than: 8  }
  validates :hours, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 24 }
  validates :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 60 }
  validates :quota, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :ascending, -> { order('hours ASC').order('minutes ASC') }

  after_save :push_changes
  after_destroy :push_changes
  push_targets [ Channel::STOCK_CHANNEL ]

  private

  def no_conflict
    conflicts = AppointmentSlotPreset
      .where({ day: day, hours: hours, minutes: minutes })
      .where.not({ id: self.id })
      .count

    if conflicts.positive?
      errors.add(:base, I18n.t("appointment_slots.already_exists"))
    end
  end
end
