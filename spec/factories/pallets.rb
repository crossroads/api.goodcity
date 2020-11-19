# frozen_String_literal: true

FactoryBot.define do
  factory :pallet do
    pallet_number { 'MyString' }
    description   { 'MyString' }
    comments      { 'MyText' }
  end
end
