class District < ActiveRecord::Base
  belongs_to :territory
  has_many :user

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name
end
