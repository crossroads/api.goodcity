# frozen_String_literal: true

FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    crm_id          { rand(10000) }
  end
end
