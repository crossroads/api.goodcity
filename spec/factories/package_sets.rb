FactoryBot.define do
  factory :package_set do
    description { FFaker::Lorem.sentence }
    package_type { create(:package_type) }

    trait :with_packages do
      packages { create_list(:package, rand(3)+1, package_set_id: id) }
    end
  end
end
