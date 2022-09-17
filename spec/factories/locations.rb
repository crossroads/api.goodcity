# frozen_String_literal: true

FactoryBot.define do
  factory :location do
    sequence(:building) { |n| ("A".."Z").to_a[n%26] << "#{n}" }
    sequence(:area)     { |n| n }

    trait :multiple do
      building { 'Multiple' }
    end
  end
end
