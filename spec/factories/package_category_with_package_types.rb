FactoryGirl.define do
  factory :package_categories_package_type do
    association :package_type, factory: :base_package_type
    association :package_category, factory: :child_package_category
  end
end
