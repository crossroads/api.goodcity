# frozen_string_literal: true

FactoryBot.define do
  factory :medical do
    brand { FFaker::Company.name }
    association :country, strategy: :build
    expiry_date { 10.days.from_now }
  end
end
