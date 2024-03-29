# frozen_String_literal: true

FactoryBot.define do
  factory :packages_location do
    association :package, factory: :package
    association :location
    quantity    { 1 }
  end
end
