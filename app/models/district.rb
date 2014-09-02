class District < ActiveRecord::Base

  include CacheableJson

  belongs_to :territory, inverse_of: :districts

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name

end
