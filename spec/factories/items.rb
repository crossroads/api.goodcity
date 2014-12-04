# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item do
    donor_description      { Faker::Lorem.sentence }
    state                  'submitted'
    reject_reason { Faker::Lorem.sentence }

    association :donor_condition
    association :item_type
    association :rejection_reason

    trait :with_packages do
      packages             { create_list(:package, 2) }
    end

    trait :with_images do
      images               { create_list(:image, 1) << create(:image, favourite: true) }
    end

    trait :with_offer do
      association :offer
    end

    trait :paranoid do
      state  { ["submitted", "accepted", "rejected"].sample }
      images { create_list(:image, 2) }
    end

  end
end
