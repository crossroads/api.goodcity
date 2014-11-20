class ItemType < ActiveRecord::Base

  include CacheableJson

  has_many :items, inverse_of: :item_type
  has_many :packages, foreign_key: :package_type_id, inverse_of: :package_type

  validates :name_en, presence: true, uniqueness: true

  translates :name

end
