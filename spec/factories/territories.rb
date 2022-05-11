# frozen_String_literal: true

FactoryBot.define do
  factory :territory do
    sequence(:name_en) { |n| generate(:territories).keys.sort[n%generate(:territories).keys.size] }
    name_zh_tw         { generate(:territories)[name_en][:name_zh_tw] }
    initialize_with    { Territory.find_or_initialize_by(name_en: name_en) }
    
    factory :territory_districts do
      transient do
        districts_count { 5 }
      end

      after(:create) do |territory, evaluator|
        FactoryBot.create_list(:district, evaluator.districts_count, territory: territory)
        territory.reload
      end
    end
  end
end
