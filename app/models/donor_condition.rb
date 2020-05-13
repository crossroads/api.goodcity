class DonorCondition < ActiveRecord::Base
  include CacheableJson
  include RollbarSpecification

  has_many :items
  has_many :packages

  translates :name

  validates :name_en, presence: true

  def self.donor_condition_for(type=nil)
    return where(nil) if type
    where(visible_to_package: false)
  end
end
