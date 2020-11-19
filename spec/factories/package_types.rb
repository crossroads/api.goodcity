# frozen_String_literal: true

FactoryBot.define do
  factory :base_package_type, class: :PackageType do
    code               { generate(:package_types).keys.sample }
    name_en            { generate(:package_types)[code][:name_en] }
    name_zh_tw         { generate(:package_types)[code][:name_zh_tw] }
    other_terms_en     { generate(:package_types)[code][:other_terms_en] }
    other_terms_zh_tw  { generate(:package_types)[code][:other_terms_zh_tw] }
    allow_expiry_date  { generate(:package_types)[code][:package_types] }
    visible_in_selects { true }
    initialize_with    { PackageType.find_or_initialize_by(code: code) }
    association        :location
    allow_stock        { false }

    trait :allow_expiry_date do
      allow_expiry_date { true }
    end

    trait :disallow_expiry_date do
      allow_expiry_date { false }
    end
  end

  factory :package_type, parent: :base_package_type do
    # Create the default and other sub package types
    after(:create) do |package|
      default_packages = (generate(:package_types)[package.code][:default_packages] || "").split(", ")
      default_packages.each do |code|
        child_package = create(:base_package_type, code: code)
        create(:subpackage_type, package_type: package, child_package_type: child_package, is_default: true)
      end
      other_packages = (generate(:package_types)[package.code][:other_packages] || "").split(", ")
      other_packages.each do |code|
        child_package = create(:base_package_type, code: code)
        create(:subpackage_type, package_type: package, child_package_type: child_package, is_default: false)
      end
    end
  end
end
