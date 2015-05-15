class PackageType < ActiveRecord::Base
  include CacheableJson

  has_many :subpackage_types
  has_many :child_package_types, through: :subpackage_types,
    source: :child_package_type
  has_many :items, inverse_of: :package_type
  has_many :packages, inverse_of: :package_type

  translates :name, :other_terms
end
