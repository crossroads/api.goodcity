# frozen_String_literal: true

FactoryBot.define do
  factory :company do
    name { MyString }
    crm_id { 1 }
    created_by_id  { 1 }
  end
end
