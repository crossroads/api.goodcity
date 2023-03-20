# frozen_String_literal: true

FactoryBot.define do
  factory :location do
    sequence(:building) { |n|  seq[n%seq.size]['building'] }
    sequence(:area)     { |n|  seq[n%seq.size]['area'] }
    initialize_with     { Location.find_or_initialize_by(building: building, area: area) } # avoid duplicates

    transient do
      seq { @locations ||= YAML.load_file("#{Rails.root}/db/locations.yml") }
    end

    trait :multiple do
      building          { 'Multiple' }
      sequence(:area)   { |n| n }
    end
  end
end
