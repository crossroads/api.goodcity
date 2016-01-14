class CancellationReason < ActiveRecord::Base

  include CacheableJson

  has_many :offers
  translates :name
  validates :name_en, presence: true

end
