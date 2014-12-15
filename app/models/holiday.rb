class Holiday < ActiveRecord::Base
  by_star_field :holiday

  scope :within_days, ->(days) { between_times(Time.zone.now, Time.zone.now + days) }
end
