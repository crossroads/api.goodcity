# frozen_String_literal: true

FactoryBot.define do
  factory :printer do
    association :location
    active { false }
    name { FFaker::Name.name }
    host { FFaker::Name.name }
    port { FFaker::Name.name }
    username { FFaker::Name.name }
    password { FFaker::Name.name }

    trait :active do
      active { true }
    end
  end
end
