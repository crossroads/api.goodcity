class Timeslot < ActiveRecord::Base
  include CacheableJson

  translates :name
end
