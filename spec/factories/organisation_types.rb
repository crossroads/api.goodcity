FactoryBot.define do
  factory :organisation_type do
    sequence(:name_en)        { |n| seq[n%seq.size][:name_en] }
    sequence(:name_zh_tw)     { |n| seq[n%seq.size][:name_zh_tw] }
    sequence(:category_en)    { |n| seq[n%seq.size][:category_en] }
    sequence(:category_zh_tw) { |n| seq[n%seq.size][:category_zh_tw] }
    initialize_with           { OrganisationType.find_or_initialize_by(name_en: name_en) } # avoid duplicates

    transient do
      seq { @organisation_types ||= YAML.load_file("#{Rails.root}/db/organisation_types.yml") }
    end
  end
end
