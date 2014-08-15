# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

donor_conditions = YAML.load_file("#{Rails.root}/db/donor_conditions.yml")
donor_conditions.each do |name, value|
  FactoryGirl.create :donor_condition, name_en: name, name_zh_tw: value[:name_zh_tw]
end

item_types = YAML.load_file("#{Rails.root}/db/item_types.yml")
item_types.each do |code, value|
  FactoryGirl.create :item_type, code: code, name_en: value[:name_en], name_zh_tw: value[:name_zh_tw]
end

rejection_reasons = YAML.load_file("#{Rails.root}/db/rejection_reasons.yml")
rejection_reasons.each do |name_en, value|
  FactoryGirl.create :rejection_reason, name_en: name_en, name_zh_tw: value[:name_zh_tw]
end

districts = YAML.load_file("#{Rails.root}/db/districts.yml")
districts.each do |name_en, value|
  # FactoryGirl creates the correct territory for us
  FactoryGirl.create :district, name_en: name_en
end

# Don't run the following setup on the live server.
# This is for dummy data
unless ENV['LIVE'] == "true"

  10.times { FactoryGirl.create :offer }

  FactoryGirl.create :reviewer
  FactoryGirl.create :supervisor
  FactoryGirl.create :administrator

end
