# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :territory do
    name       { generate(:territories).keys.sample }
    name_zh_tw { generate(:territories)[name] }
    initialize_with { Territory.find_or_initialize_by(name: name) }
  end
end
