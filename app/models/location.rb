class Location < ApplicationRecord
  include CacheableJson
  include PushUpdates

  has_many :packages_locations
  has_many :packages, through: :packages_locations
  has_many :package_types, inverse_of: :location
  has_one  :printer

  # GET /package_types (and ?stock=true) embed each type's default location, so a rename must re-key those
  # cached bodies too: CacheableJson's own after_save only clears Location's key. update_all moves
  # updated_at (what PackageType.cache_key is built from, in every locale) without callbacks, versions or
  # any change to a response shape. A retire changes neither building nor area, so it doesn't need this.
  after_save :rekey_package_type_caches, if: -> { saved_change_to_building? || saved_change_to_area? }

  # Retired locations stay on every record that points at them, but the new stock app stops offering them for new
  # stock (GET /locations?exclude_retired=true). The legacy apps don't read retired_at.
  scope :not_retired, -> { where(retired_at: nil) }

  # True when a foreign key still points at the location, so DELETE would answer 409 (ForeignKeyDeletionError).
  # The tables are the five with a foreign key to locations (db/schema.rb); each probe uses its location_id index.
  IN_USE_SQL = %w[packages_locations packages_inventories stocktakes printers package_types].map { |table|
    "EXISTS (SELECT 1 FROM #{table} WHERE #{table}.location_id = locations.id)"
  }.join(" OR ").freeze

  # The ids of every location in use, in one query (the Locations admin list).
  def self.in_use_ids
    unscoped.where(IN_USE_SQL).pluck(:id).to_set
  end

  def in_use?
    Location.unscoped.where(id: id).where(IN_USE_SQL).exists?
  end

  def retired?
    retired_at.present?
  end

  # PATCH /locations/:id sends location: { retired: true|false }. Retiring an already-retired location keeps its stamp.
  def retired=(value)
    self.retired_at = ActiveModel::Type::Boolean.new.cast(value) ? (retired_at || Time.current) : nil
  end

  def label
    "#{building}#{area}"
  end

  # to satisfy PushUpdate module
  def offer
    nil
  end

  def self.search(key)
    where("building || area ILIKE ?", "%#{key}%")
  end

  def display_name
    "#{building} #{area}"
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
    location_ids = Version.item_location_changed(user_id)
                          .limit(15)
                          .map(&:location_id)
    locations = Location.where(id: location_ids)
                        .inject({}) { |h, v| h[v.id] = v; h }
    # We want most recently used first so preserve location_ids order
    # and ensure possible nils are removed
    location_ids.map { |id| locations[id] }.compact
  end

  private

  def rekey_package_type_caches
    package_types.update_all(updated_at: Time.current)
  end
end
