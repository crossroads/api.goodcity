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
    where("building LIKE :query OR area LIKE :query", query: "%#{key}%")
  end
end
