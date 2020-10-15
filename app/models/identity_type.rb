class IdentityType < ApplicationRecord
  include CacheableJson

  translates :name
end
