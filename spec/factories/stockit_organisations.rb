# frozen_String_literal: true

FactoryBot.define do
  factory :stockit_organisation do
    name { FFaker::Company.name }
  end
end
