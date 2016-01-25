class CancellationReason < ActiveRecord::Base

  include CacheableJson

  has_many :offers
  translates :name
  validates :name_en, presence: true

  def self.unwanted
    find_by(name_en: "Unwanted")
  end

  def self.donor_cancelled
    find_by(name_en: "Donor cancelled")
  end

end
