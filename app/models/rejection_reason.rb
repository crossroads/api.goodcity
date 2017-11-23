class RejectionReason < ActiveRecord::Base

  include CacheableJson
  include RollbarSpecification

  has_many :items
  translates :name
  validates :name_en, presence: true

end
