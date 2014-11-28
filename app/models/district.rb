class District < ActiveRecord::Base

  include CacheableJson

  belongs_to :territory, inverse_of: :districts
  has_many :addresses

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name

  def self.location_json(district_id)
    district = where(id: district_id).try(:first) || first
    [
      [22.312516,114.217874, district.name],
      [22.3741183,113.9927744, "Crossroads Foundation"]
    ].to_json
  end

end
