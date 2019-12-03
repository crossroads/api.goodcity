class Printer < ActiveRecord::Base
  has_many   :users
  belongs_to :location

  scope :active, -> { where(active: true) }
end
