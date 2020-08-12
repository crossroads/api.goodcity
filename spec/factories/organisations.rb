# frozen_String_literal: true

FactoryBot.define do
  factory :organisation do
    name_en { FFaker::Company.name }
    name_zh_tw { FFaker::Company.name }
    description_en { FFaker::Lorem.words(rand(2..10)).join(' ') }

    description_zh_tw { FFaker::Lorem.words(rand(2..10)).join(' ') }

    registration { (rand(89)+10).to_s+"/"+(rand(10000)+10000).to_s }
    website { FFaker::Internet.http_url }
    association :country
    association :district
    association :organisation_type
  end
end
