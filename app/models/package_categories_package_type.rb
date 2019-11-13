class PackageCategoriesPackageType < ActiveRecord::Base
  include RollbarSpecification
  belongs_to :package_type, touch: true
  belongs_to :package_category, touch: true

  validates :package_type_id, uniqueness: { scope: :package_category_id }
end
