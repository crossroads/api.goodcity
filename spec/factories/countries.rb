FactoryBot.define do
  factory :country do
    name_en         { FFaker::Address.country }
    name_zh_tw      { name_en }
    initialize_with { Country.find_or_initialize_by(name_en: name_en) } # avoid duplicates
  end
end
