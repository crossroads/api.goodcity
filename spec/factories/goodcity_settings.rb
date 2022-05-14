# frozen_String_literal: true

FactoryBot.define do
  factory :goodcity_setting do
    sequence(:key)  { |n| "stock.page.setting#{n}" }
    value           { rand(100) }
    description     { "Description" }
  end
end
