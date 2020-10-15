# frozen_String_literal: true

FactoryBot.define do
  factory :goodcity_request do
    association :order
    association :package_type
    quantity { 1 }
    description { 'MyText' }
    created_by_id { order&.created_by_id }
  end
end
