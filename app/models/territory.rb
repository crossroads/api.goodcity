class Territory < ApplicationRecord

  include CacheableJson

  has_many :districts, inverse_of: :territory
  validates :name_en, presence: true

  translates :name

  scope :with_eager_load, -> { includes( :districts ) }

end
