class DonorCondition < ActiveRecord::Base

  include CacheableJson

  has_many :items
  translates :name
  validates :name_en, presence: true

end
