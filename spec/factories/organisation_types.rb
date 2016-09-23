FactoryGirl.define do
  factory :organisation_type do
    name_en { FFaker::Company.name }
    name_zh { FFaker::Company.name }
    category_en { FFaker::Name.name }
    category_zh { FFaker::Name.name }
  end
end
