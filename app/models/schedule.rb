class Schedule < ActiveRecord::Base
  has_many :deliveries, inverse_of: :schedule

  validate :no_public_holiday_conflict

  def formatted_date_and_slot
    "#{slot_name},
    #{scheduled_at.strftime("%a #{scheduled_at.day.ordinalize}")}"
  end

  private

  def no_public_holiday_conflict
    if Holiday.is_holiday(scheduled_at)
      errors.add(:base, I18n.t('schedule.holiday_conflict', date: scheduled_at.to_date))
    end
  end
end
