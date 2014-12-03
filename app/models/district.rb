class District < ActiveRecord::Base

  include CacheableJson

  belongs_to :territory, inverse_of: :districts
  has_many :addresses

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name

  CROSSROADS_ADDRESS = [22.3741183,113.9927744, "Crossroads Foundation"]

  default_scope do
    where("latitude IS NOT NULL AND longitude IS NOT NULL")
  end

  def self.location_json(district_id)
    district = where(id: district_id).try(:first) || first
    [
      [district.latitude, district.longitude, district.name],
      CROSSROADS_ADDRESS
    ].to_json
  end

end
