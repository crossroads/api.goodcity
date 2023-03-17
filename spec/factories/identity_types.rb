# frozen_String_literal: true

FactoryBot.define do
  factory :identity_type do
    sequence(:identifier) { |n| seq.keys.sort[n%seq.keys.size] }
    name_en               { seq[identifier][:name_en] }
    name_zh_tw            { seq[identifier][:name_zh_tw] }
    initialize_with       { IdentityType.find_or_initialize_by(name_en: name_en) } # avoid duplicates

    transient do
      seq { @identity_types ||= YAML.load_file("#{Rails.root}/db/identity_types.yml") }
    end
  end
end
