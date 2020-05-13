# rake goodcity:add_mix_donor_condition
namespace :goodcity do
  desc 'Add "MIX" donor_condition'
  task add_mix_donor_condition: :environment do
    donor_conditions = YAML.load_file("#{Rails.root}/db/donor_conditions.yml")

    donor_conditions.each do |name, value|
      DonorCondition.where(name_en: name).first_or_create do |donor_condition|
        donor_condition.name_en = name
        donor_condition.name_zh_tw = value[:name_zh_tw]
        donor_condition.visible_to_package = value[:visible_to_package]
      end
    end
  end
end