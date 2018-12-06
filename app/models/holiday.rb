class Holiday < ActiveRecord::Base
  include RollbarSpecification
  by_star_field :holiday

  validates :holiday, :name, presence: true
  validates :holiday, uniqueness: true

  before_save :set_year, if: :holiday_changed?

  scope :within_days, ->(days) {
    between_times(Time.zone.now, Time.zone.now + days) }

  def self.is_holiday(date)
    Holiday.where(" date(holiday AT TIME ZONE 'HKT') = ?", date.to_date).count > 0
  end

  private

  def set_year
    self.year = holiday.year
  end
end
