# frozen_String_literal: true

FactoryBot.define do
  factory :goodcity_request do
    quantity      { 1 }
    description   { 'Description' }
    created_by_id { order&.created_by_id }
    order
    package_type
  end
end
