# frozen_String_literal: true

FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    crm_id          { rand(10000) }
    created_by      { association :user, strategy: :build }
  end
end
