# frozen_String_literal: true

FactoryBot.define do
  factory :base_package_type, class: :PackageType do
    sequence(:code)         { |n| pt.keys.sort[n%pt.keys.size] }
    name_en                 { pt[code][:name_en] }
    name_zh_tw              { pt[code][:name_zh_tw] }
    other_terms_en          { pt[code][:other_terms_en] }
    other_terms_zh_tw       { pt[code][:other_terms_zh_tw] }
    allow_expiry_date       { code.starts_with?("M") }
    visible_in_selects      { true }
    allow_package           { true }
    default_value_hk_dollar { pt[code][:default_value_hk_dollar] }
    allow_box               { pt[code][:allow_box] || false }
    allow_pallet            { pt[code][:allow_pallet] || false }
    description_en          { name_en }
    description_zh_tw       { name_zh_tw }
    length                  { pt[code][:length] || rand(100) }
    width                   { pt[code][:width]  || rand(100) }
    height                  { pt[code][:height] || rand(100) }
    customs_value_usd       { rand(10000) }
    association             :location
    subform do
      pt[code][:subform] ||
        if code.starts_with?("M")
          'medical'
        elsif code.starts_with?("E")
          'electrical'
        end
    end
    initialize_with         { PackageType.find_or_initialize_by(code: code) }

    transient do
      pt { generate(:package_types) }
    end

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
