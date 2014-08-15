class Territory < ActiveRecord::Base
  has_many :districts
  validates :name_en, presence: true

  translates :name

  scope :with_eager_load, -> { includes( :districts ) }

end
