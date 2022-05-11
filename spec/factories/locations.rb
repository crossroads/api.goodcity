# frozen_String_literal: true

FactoryBot.define do
  factory :location do
    building        { building_and_area["building"] }
    area            { building_and_area["area"] }
    initialize_with { Location.find_or_initialize_by(area: area, building: building) }

    transient do
      building_and_area { generate(:building_and_area) }
    end

    trait :multiple do
      building { 'Multiple' }
    end
  end

  sequence(:building_and_area) do |n|
    locations = FactoryBot.generate(:locations)
    locations[n%locations.size]
  end

end
