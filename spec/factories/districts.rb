# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :district do
    name            { generate(:districts).keys.sample }
    name_zh_tw      { generate(:districts)[name].first }
    territory       { create(:territory, name: generate(:districts)[name].last) }
    initialize_with { District.find_or_initialize_by(name: name) }
  end
end
