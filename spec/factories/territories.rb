# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :territory do
    name_en         { generate(:territories).keys.sample }
    name_zh_tw      { generate(:territories)[name_en][:name_zh_tw] }
    initialize_with { Territory.find_or_initialize_by(name_en: name_en) }
    factory :territory_districts do
      ignore do
        districts_count 5
      end

      after(:create) do |territory, evaluator|
        FactoryGirl.create_list(:district, evaluator.districts_count, territory: territory)
        territory.reload
      end
    end
  end
end
