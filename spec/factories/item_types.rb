# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_type do
    code            { generate(:item_types).keys.sample }
    name_en         { generate(:item_types)[code][:name_en] }
    #name_zh_tw      { generate(:item_types)[code][:name_zh_tw] }
    name_zh_tw      { generate(:random_chinese_string) }
    parent_id       {
      parent_code = generate(:item_types)[code][:parent_code]
      if parent_code
        create(:item_type, code: parent_code).id
      end
    }
    initialize_with { ItemType.find_or_initialize_by(code: code) }
  end
end
