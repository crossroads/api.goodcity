FactoryBot.define do
  factory :country do
    sequence(:name_en) { |n| seq.sort[n%seq.size] }
    name_zh_tw      { name_en }
    initialize_with { Country.find_or_initialize_by(name_en: name_en) } # avoid duplicates

    transient do
      seq { @countries ||= YAML.load_file("#{Rails.root}/db/countries.yml") }
    end
  end

end
