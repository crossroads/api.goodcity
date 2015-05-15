class PackageType < ActiveRecord::Base
  has_many :subpackage_types
  has_many :child_package_types, through: :subpackage_types,
    source: :child_package_type
end
