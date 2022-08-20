# frozen_String_literal: true

FactoryBot.define do
  factory :box do
    sequence(:box_number) { |n| "Box number #{n}" }
    description           { 'Description' }
    comments              { 'Comments' }
    pallet
  end
end
