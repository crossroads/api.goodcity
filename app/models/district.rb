class District < ActiveRecord::Base
  belongs_to :territory
  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name
end
