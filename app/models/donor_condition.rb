class DonorCondition < ActiveRecord::Base
  include CacheableJson
  include RollbarSpecification

  has_many :items
  has_many :packages

  translates :name

  validates :name_en, presence: true
end
