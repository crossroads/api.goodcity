class District < ActiveRecord::Base
  belongs_to :territory, inverse_of: :districts
  has_many :user

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name
end
