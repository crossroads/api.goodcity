class PackageCategory < ActiveRecord::Base
  include CacheableJson

  translates :name

  has_many :package_sub_categories
  has_many :package_types, through: :package_sub_categories
  belongs_to :parent_category, class_name: :PackageCategory, foreign_key: :parent_id
  has_many :child_categories, class_name: :PackageCategory, foreign_key: :parent_id
end
