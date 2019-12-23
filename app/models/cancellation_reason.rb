class CancellationReason < ActiveRecord::Base
  include CacheableJson
  include RollbarSpecification

  has_many :offers
  translates :name
  validates :name_en, presence: true

  scope :visible_to_offer, -> { where(visible_to_offer: true) }
  scope :visible_to_order, -> { where(visible_to_order: true) }

  def self.unwanted
    find_by(name_en: "Unwanted")
  end

  def self.donor_cancelled
    find_by(name_en: "Donor cancelled")
  end
end
