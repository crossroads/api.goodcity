class Location < ActiveRecord::Base
  include CacheableJson

  has_many :packages
end
