class Printer < ActiveRecord::Base
  belongs_to :location

  scope :active, -> { where(active: true) }
end
