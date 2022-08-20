# frozen_String_literal: true

FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| generate(:permissions_roles).keys.sort[n%generate(:permissions_roles).keys.size] }
    initialize_with { Permission.find_or_initialize_by(name: name) } # avoid duplicate roles

    trait :api_write do
      name { 'api-write' }
    end
  end
end
