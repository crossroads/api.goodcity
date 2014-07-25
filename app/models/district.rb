class District < ActiveRecord::Base
  belongs_to :territory
  validates :name, presence: true
  validates :territory_id, presence: true
end
