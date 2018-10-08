class IdentityType < ActiveRecord::Base
  include CacheableJson

  translates :name
end
