# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :donor_condition do
    sequence(:name_en) { |n| seq.keys.sort[n%seq.keys.size] }
    name_zh_tw         { seq[name_en][:name_zh_tw] }
    visible_to_donor   { seq[name_en][:visible_to_donor] }
    initialize_with    { DonorCondition.find_or_initialize_by(name_en: name_en) } # avoid duplicates

    transient do
      seq { @donor_conditions ||= YAML.load_file("#{Rails.root}/db/donor_conditions.yml") }
    end

  end
end
