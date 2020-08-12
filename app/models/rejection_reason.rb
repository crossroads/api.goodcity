class RejectionReason < ApplicationRecord
  include CacheableJson
  include RollbarSpecification

  has_many :items
  translates :name
  validates :name_en, presence: true
end
