class Location < ActiveRecord::Base
  include CacheableJson
  include PushUpdates

  has_many :packages
  
  # to satisfy PushUpdate module
  def offer
    nil
  end
end
