# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item do
    donor_description      { Faker::Lorem.sentence }
    state                  'draft'
    item_type_id           { create(:item_type).id }
    rejection_reason_id    { create(:rejection_reason).id }
    rejection_other_reason { Faker::Lorem.sentence }

    donor_condition

    trait :with_packages do
      packages             { create_list(:package, 2) }
    end

    trait :with_images do
      images               { create_list(:image, 2) }
    end

    trait :with_offer do
      association :offer
    end

    factory :paranoid_item do
      state  { ["pending", "accepted", "rejected"].sample }
      images { create_list(:image, 2) }
    end

  end
end
