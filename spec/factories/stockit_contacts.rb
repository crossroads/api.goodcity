# frozen_String_literal: true

FactoryBot.define do
  factory :stockit_contact do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    mobile_phone_number { '' }
    phone_number { FFaker::PhoneNumber.short_phone_number }
  end
end
