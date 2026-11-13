# frozen_String_literal: true

FactoryBot.define do
  factory :location do
    transient do
      seed { generate(:location_seed) }
    end

    building            { seed['building'] }
    area                { seed['area'] }
    initialize_with     { Location.find_or_initialize_by(building: building, area: area) } # avoid duplicates

    trait :multiple do
      building          { 'Multiple' }
      sequence(:area)   { |n| n }
    end
  end

  # One counter shared by this factory and by factories that look locations up from
  # spec/fixtures/locations.yml, so successive calls still yield different locations
  sequence :location_seed do |n|
    @locations ||= YAML.load_file("#{Rails.root}/db/locations.yml")
    @locations[n % @locations.size].slice('building', 'area')
  end
end
