class Location < ActiveRecord::Base
  include CacheableJson
  include PushUpdates

  has_many :packages

  scope :dispatch_location, -> { find_by(building: 'Dispatched') }

  # to satisfy PushUpdate module
  def offer
    nil
  end

  def self.search(key)
    where("building ILIKE :query OR area ILIKE :query", query: "%#{key}%")
  end

  def self.recently_used(user_id)
    select("DISTINCT ON (locations.id) locations.id, building, area, versions.created_at").
    joins("INNER JOIN versions ON ((object_changes -> 'location_id' ->> 1) = CAST(locations.id AS TEXT))").
    joins("INNER JOIN packages ON (packages.id = versions.item_id AND versions.item_type = 'Package')").
    where("versions.event = 'update' AND
      (object_changes ->> 'location_id') IS NOT NULL AND
      CAST(whodunnit AS integer) = ? AND
      versions.created_at >= ? ", user_id, 15.days.ago).
    order("locations.id, versions.created_at DESC")
  end
end
