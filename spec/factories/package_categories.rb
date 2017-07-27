FactoryGirl.define do
  factory :package_category, aliases: [:parent_package_category] do
    name_en    { FFaker::Lorem.characters(5) }
    name_zh_tw { FFaker::Lorem.characters(5) }

    trait :with_package_type do
      after(:create) do |package_category|
        package_type = build(:package_type)
        package_type.package_categories << package_category
        package_type.save
      end
    end

    factory :child_package_category do
      after(:build) do |category|
        category.parent_category = build :parent_package_category
      end
    end

    factory :package_category_with_package_type, parent: :child_package_category do
      after(:build) do |category|
        create_list :package_categories_package_type, 2, package_category: category
      end
    end
  end
end
