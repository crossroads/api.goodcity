class PackageType < ActiveRecord::Base
  include CacheableJson

  has_many :subpackage_types
  has_many :child_package_types, through: :subpackage_types,
    source: :child_package_type

  has_many :default_subpackage_types, -> { where is_default: true },
    class_name: :SubpackageType
  has_many :default_child_package_types, through: :default_subpackage_types,
    source: :default_child_package_type

  has_many :other_subpackage_types, -> { where is_default: false },
    class_name: :SubpackageType
  has_many :other_child_package_types, through: :other_subpackage_types,
    source: :other_child_package_type

  has_many :items, inverse_of: :package_type
  has_many :packages, inverse_of: :package_type

  translates :name, :other_terms
end
