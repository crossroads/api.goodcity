# frozen_String_literal: true

FactoryBot.define do
  factory :stockit_local_order do
    client_name      { FFaker::Name.first_name }
    hkid_number      { 'HKID number' }
    reference_number { 'Reference number' }
  end
end
