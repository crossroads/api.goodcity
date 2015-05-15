FactoryGirl.define do
  factory :subpackage_type do
    package_type
    association :child_package_type, factory: :package_type
    is_default false
  end
end
