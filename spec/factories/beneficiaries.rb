# frozen_String_literal: true

FactoryBot.define do
  factory :beneficiary do
    identity_type         { create(:identity_type) }
    identity_number       { rand(10000) }
    title                 { %w(Mr Mrs).sample }
    sequence(:first_name) { |n| "First name #{n}" }
    sequence(:last_name)  { |n| "Last name #{n}" }
    phone_number          { generate(:mobile) }

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end
  end
end
