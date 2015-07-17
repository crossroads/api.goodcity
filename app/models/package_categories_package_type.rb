class PackageCategoriesPackageType < ActiveRecord::Base
  belongs_to :package_type
  belongs_to :package_category

  validates :package_type_id, uniqueness: { scope: :package_category_id }
end
