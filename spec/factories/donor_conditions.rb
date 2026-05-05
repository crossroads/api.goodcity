# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :donor_condition do
    sequence(:name_en) { |n| seq.keys.sort[n%seq.keys.size] }
    name_zh_tw         { seq[name_en][:name_zh_tw] }
    visible_to_donor   { seq[name_en][:visible_to_donor] }
    initialize_with    { DonorCondition.find_or_initialize_by(name_en: name_en) } # avoid duplicates

    transient do
      # Ruby 3.1+ (Psych 4) makes YAML.load/load_file safe by default, which
      # rejects YAML tags like !!omap used in `db/donor_conditions.yml`.
      seq do
        path = "#{Rails.root}/db/donor_conditions.yml"
        @donor_conditions ||= if YAML.respond_to?(:unsafe_load_file)
          YAML.unsafe_load_file(path)
        else
          YAML.load_file(path)
        end
      end
    end

  end
end
