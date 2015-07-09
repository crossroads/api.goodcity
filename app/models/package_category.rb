class PackageCategory < ActiveRecord::Base
  has_many :package_sub_categories
  has_many :package_types, through: :package_sub_categories
end
