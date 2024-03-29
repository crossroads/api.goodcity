FactoryBot.define do
  factory :package_category, aliases: [:parent_package_category] do
    sequence(:name_en) { |n| "Package category #{n}" }
    name_zh_tw         { name_en }

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
