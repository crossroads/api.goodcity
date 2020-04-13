# frozen_string_literal: true

FactoryBot.define do
  factory :medical do
    brand { FFaker::Company.name }
    association :country, strategy: :build
  end
end
