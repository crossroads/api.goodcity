FactoryBot.define do
  factory :printer do
    active false
    location_id 1
    name { FFaker::Name.name }
    host { FFaker::Name.name }
    port { FFaker::Name.name }
    username { FFaker::Name.name }
    password { FFaker::Name.name }

    trait :active do
      active true
    end
  end
end
