class CancellationReason < ActiveRecord::Base
  include CacheableJson
  include RollbarSpecification
  CANCELLATION_REASONS_TYPE = ["offer", "order"].freeze

  has_many :offers
  has_many :orders
  translates :name
  validates :name_en, presence: true

  CANCELLATION_REASONS_TYPE.each do |type|
    scope :"visible_to_#{type}", -> { where("visible_to_#{type}": true) }
  end

  def self.unwanted
    find_by(name_en: "Unwanted")
  end

  def self.donor_cancelled
    find_by(name_en: "Donor cancelled")
  end

  def self.cancellation_reasons_for(type)
    return where unless CANCELLATION_REASONS_TYPE.include?(type)
    send("visible_to_#{type}")
  end
end
