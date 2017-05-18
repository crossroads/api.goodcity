FactoryGirl.define do
  factory :organisation_type do
    name_en { FFaker::Company.name }
    name_zh_tw { FFaker::Company.name }
    category_en { FFaker::Name.name }
    category_zh_tw { FFaker::Name.name }
  end
end
