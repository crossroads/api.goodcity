class District < ActiveRecord::Base

  include I18nCacheKey

  belongs_to :territory, inverse_of: :districts#, touch: true
  has_many :addresses

  validates :name_en, presence: true
  validates :territory_id, presence: true

  translates :name

end
