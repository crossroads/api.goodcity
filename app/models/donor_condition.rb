class DonorCondition < ActiveRecord::Base

  has_many :items
  translates :name
  validates :name_en, presence: true

end
