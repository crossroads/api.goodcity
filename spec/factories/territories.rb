# frozen_String_literal: true

# Usually better to create a district instead which will create the appropriate territory
#   let(:territory) { create(:district).territory }
#
FactoryBot.define do
  factory :territory do
    sequence(:name_en) { |n| generate(:territories).keys.sort[n%generate(:territories).keys.size] }
    name_zh_tw         { generate(:territories)[name_en][:name_zh_tw] }
    initialize_with    { Territory.find_or_initialize_by(name_en: name_en) }
  end
end
