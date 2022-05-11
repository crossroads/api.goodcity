# frozen_String_literal: true

FactoryBot.define do
  factory :beneficiary do
    identity_type   { create(:identity_type) }
    identity_number { rand(10000) }
    title           { %w(Mr Mrs).sample }
    first_name      { FFaker::Name.first_name }
    last_name       { FFaker::Name.last_name }
    phone_number    { generate(:mobile) }
    created_at      { Time.now }
    updated_at      { Time.now }

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end
  end
end
