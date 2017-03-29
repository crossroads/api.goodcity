class DonorCondition < ApplicationRecord

  include CacheableJson

  has_many :items
  has_many :packages

  translates :name

  validates :name_en, presence: true

end
