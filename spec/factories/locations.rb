FactoryBot.define do
  factory :location do
    sequence(:building)
    area       { FFaker::Lorem.characters(1).upcase }
    stockit_id { rand(1000) }
    initialize_with {
      Location.find_or_initialize_by(
        area: area,
        building: building
      )
    }

    trait :dispatched do
      building 'Dispatched'
      area ''
    end

    trait :multiple do
      building 'Multiple'
    end
  end
end
