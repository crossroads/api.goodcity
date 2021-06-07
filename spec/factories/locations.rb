# frozen_String_literal: true

FactoryBot.define do
  factory :location do
    sequence(:building)
    area       { FFaker::Lorem.characters(1).upcase }
    initialize_with {
      Location.find_or_initialize_by(
        area: area,
        building: building
      )
    }

    trait :multiple do
      building { 'Multiple' }
    end
  end
end
