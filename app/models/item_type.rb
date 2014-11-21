class ItemType < ActiveRecord::Base

  include CacheableJson

  has_many :items, inverse_of: :item_type
  has_many :packages, foreign_key: :package_type_id, inverse_of: :package_type
  belongs_to :parent, foreign_key: :parent_id, class_name: 'ItemType'

  validates :name_en, presence: true

  translates :name

end
