# frozen_String_literal: true

FactoryBot.define do
  factory :pallet do
    sequence(:pallet_number) { |n| "Pallet #{n}" }
    description              { "Description" }
    comments                 { "Comments" }
  end
end
