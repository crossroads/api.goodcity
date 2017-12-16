FactoryGirl.define do
  factory :base_package_type, class: :PackageType do
    code               { generate(:package_types).keys.sample }
    name_en            { generate(:package_types)[code][:name_en] }
    name_zh_tw         { generate(:package_types)[code][:name_zh_tw] }
    other_terms_en     { generate(:package_types)[code][:other_terms_en] }
    other_terms_zh_tw  { generate(:package_types)[code][:other_terms_zh_tw] }
    visible_in_selects { true }
    initialize_with    { PackageType.find_or_initialize_by(code: code) }
  end

  factory :package_type, parent: :base_package_type do
    trait :with_stockit_id do
      sequence(:stockit_id) { |n| n }
    end
  end
end
