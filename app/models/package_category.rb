class PackageCategory < ApplicationRecord
  include CacheableJson

  translates :name

  has_many :package_categories_package_types
  has_many :package_types, through: :package_categories_package_types
  belongs_to :parent_category, class_name: :PackageCategory, foreign_key: :parent_id
  has_many :child_categories, class_name: :PackageCategory, foreign_key: :parent_id
end
