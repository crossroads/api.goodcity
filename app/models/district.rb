class District < ActiveRecord::Base

  include CacheableJson

  belongs_to :territory, inverse_of: :districts
  has_many :addresses

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name

  CROSSROADS_ADDRESS = [22.3748365, 113.9931416, "Crossroads Foundation"]

  default_scope do
    where("latitude IS NOT NULL AND longitude IS NOT NULL")
  end

  def self.crossroads_address
    CROSSROADS_ADDRESS
  end

  def lat_lng_name
    [latitude, longitude, name]
  end

end
