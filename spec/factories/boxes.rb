# frozen_String_literal: true

FactoryBot.define do
  factory :box do
    box_number   { 'MyString' }
    description  { 'MyString' }
    comments     { 'MyText' }
    pallet
  end
end
