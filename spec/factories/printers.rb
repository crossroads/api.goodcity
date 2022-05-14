# frozen_String_literal: true

FactoryBot.define do
  factory :printer do
    sequence(:name) { |n| "Printer #{n}" }
    active          { true }
    host            { "127.0.0.1" }
    port            { 9100 }
    username        { FFaker::Name.name }
    password        { FFaker::Name.name }
    association :location

    trait :active do
      active { true }
    end
  end
end
