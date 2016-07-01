class Location < ActiveRecord::Base
  include CacheableJson
  include PushUpdates

  has_many :packages

  scope :dispatch_location, -> { find_by(building: 'Dispatched') }

  # to satisfy PushUpdate module
  def offer
    nil
  end
end
