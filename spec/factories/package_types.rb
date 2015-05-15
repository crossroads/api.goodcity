FactoryGirl.define do
  factory :package_type do
    code               { FFaker::Lorem.characters(3) }
    name_en            { FFaker::Lorem.characters(5) }
    name_zh_tw         { FFaker::Lorem.characters(5) }
    other_terms_en     { FFaker::Lorem.characters(5) }
    other_terms_zh_tw  { FFaker::Lorem.characters(5) }
  end
end
