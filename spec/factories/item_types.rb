# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_type do
    code            { generate(:item_types).keys.sample }
    name            { generate(:item_types)[code] }
    parent_id       nil
    initialize_with { ItemType.find_or_initialize_by(code: code) }
  end
end
