class Location < ActiveRecord::Base
  include CacheableJson
  include PushUpdates

  DISPATCH_BLD = 'Dispatched'.freeze
  MULTIPLE_BLD = 'Multiple'.freeze

  has_many :packages_locations
  has_many :packages, through: :packages_locations
  has_many :package_types, inverse_of: :location

  # to satisfy PushUpdate module
  def offer
    nil
  end

  def can_delete?
    packages_locations.count.zero? && package_types.count.zero?
  end

  def dispatch?
    building.eql?(DISPATCH_BLD)
  end

  def self.multiple_location
    find_by(building: MULTIPLE_BLD)
  end

  def self.dispatch_location
    find_by(building: DISPATCH_BLD)
  end

  def self.search(key)
    where("building || area ILIKE ?", "%#{key}%")
  end

  # For a given user_id, return their 15 most recently used locations
  def self.recently_used(user_id)
    # the following SQL is carefully crafted to use versions.partial_index_recent_locations
    # SELECT object_changes -> 'location_id' -> 1
    # FROM versions
    # WHERE
    #   versions.event IN ('create', 'update') AND
    #   (object_changes ? 'location_id') AND
    #   whodunnit = '2'
    # GROUP BY (object_changes -> 'location_id' -> 1)
    # ORDER BY MAX(created_at) DESC
    # LIMIT 15
    location_ids = Version.
      item_location_changed(user_id).
      limit(15).
      map(&:location_id)
    locations = Location.
      where(id: location_ids).
      where("building NOT IN (?)", ['Dispatched', 'Multiple']).
      inject({}) {|h,v| h[v.id] = v; h}
    # We want most recently used first so preserve location_ids order
    # and ensure possible nils are removed
    location_ids.map{|id| locations[id]}.compact
  end
end
