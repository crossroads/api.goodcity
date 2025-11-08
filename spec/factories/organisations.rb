# frozen_String_literal: true

FactoryBot.define do
  factory :organisation do
    sequence(:name_en) { |n| "#{FFaker::Company.name}#{n}" }
    name_zh_tw         { name_en }
    description_en     { "Description" }
    description_zh_tw  { "Description" }
    registration       { (rand(89)+10).to_s+"/"+(rand(10000)+10000).to_s }
    website            { FFaker::Internet.http_url }
    crm_account_id     { nil }
    association :country
    association :district
    association :organisation_type
  end
end
