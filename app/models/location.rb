class Location < ActiveRecord::Base
  include CacheableJson
  include PushUpdates

  has_many :packages_locations
  has_many :packages, through: :packages_locations

  scope :dispatch_location, -> { find_by(building: 'Dispatched') }
  scope :multiple_location, -> { find_by(building: 'Multiple') }

  # to satisfy PushUpdate module
  def offer
    nil
  end

  def self.search(key)
    where("building || area ILIKE ?", "%#{key}%")
  end

  def self.recently_used(user_id)
    select("DISTINCT ON (locations.id) locations.id, building, area, versions.created_at AS recently_used_at").
    joins("INNER JOIN versions ON ((object_changes -> 'location_id' ->> 1) = CAST(locations.id AS TEXT))").
    joins("INNER JOIN packages ON (packages.id = versions.item_id AND versions.item_type = 'PackagesLocation')").
    where("versions.event IN (?) AND
      (object_changes ->> 'location_id') IS NOT NULL AND
      CAST(whodunnit AS integer) = ? AND
      (object_changes ->> 'created_at') >= (?)", ['create', 'update'], user_id, 15.days.ago).
    order("locations.id, recently_used_at DESC")
  end
end

