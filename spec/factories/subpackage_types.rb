FactoryGirl.define do
  factory :subpackage_type do
    package_type
    association      :child_package_type, factory: :package_type
    is_default       false
    initialize_with  { SubpackageType.find_or_initialize_by(package_type_id: package_type.id, subpackage_type_id: child_package_type.id ) }
  end
end
