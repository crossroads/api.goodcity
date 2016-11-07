FactoryGirl.define do
  factory :base_package_type, class: :PackageType do
    code               { FFaker::Lorem.characters(3) }
    name_en            { FFaker::Lorem.characters(5) }
    name_zh_tw         { FFaker::Lorem.characters(5) }
    other_terms_en     { FFaker::Lorem.characters(5) }
    other_terms_zh_tw  { FFaker::Lorem.characters(5) }
    visible_in_selects { true }
  end

  factory :package_type, parent: :base_package_type do
    after(:create) do |package|
      child_package = create :base_package_type
      create(:subpackage_type, package_type: package,
        child_package_type: package, is_default: true)
      create(:subpackage_type, package_type: package,
        child_package_type: child_package, is_default: false)
    end
  end
end
