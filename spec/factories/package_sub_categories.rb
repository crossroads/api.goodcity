FactoryGirl.define do
  factory :package_sub_category do
    association :package_type, factory: :base_package_type
    association :package_category, factory: :child_package_category
  end
end
