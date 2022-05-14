FactoryBot.define do
  factory :package_set do
    description  { "Description" }
    package_type

    trait :with_packages do
      packages { create_list(:package, rand(3)+1, package_set_id: id) }
    end
  end
end
