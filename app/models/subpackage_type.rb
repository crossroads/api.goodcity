class SubpackageType < ActiveRecord::Base
  belongs_to :package_type
  belongs_to :child_package_type, class_name: :PackageType, foreign_key: :subpackage_type_id

  belongs_to :default_child_package_type, class_name: :PackageType, foreign_key: :subpackage_type_id
  belongs_to :other_child_package_type, class_name: :PackageType, foreign_key: :subpackage_type_id
end
