FactoryBot.define do
  factory :organisation_type do
    name_en         { org_type[:name_en] }
    name_zh_tw      { org_type[:name_zh_tw] }
    category_en     { org_type[:category_en] }
    category_zh_tw  { org_type[:category_zh_tw] }

    initialize_with { OrganisationType.find_or_initialize_by(name_en: name_en) }
    transient do
      org_type { generate(:organisation_types) }
    end

  end

  sequence(:organisation_types) do |n|
    @organisation_types = YAML.load_file("#{Rails.root}/db/organisation_types.yml")
    @organisation_types[n%@organisation_types.size]
  end

end
