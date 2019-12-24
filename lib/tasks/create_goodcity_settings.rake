
# rake goodcity:create_goodcity_settings
namespace :goodcity do
  desc "Create Goodcity Settings"
  task create_goodcity_settings: :environment do
    goodcity_settings = YAML.load_file("#{Rails.root}/db/goodcity_settings.yml")
    goodcity_settings.each do |setting|
      GoodcitySetting.where(key: setting["key"]).first_or_create(setting)
    end
  end
end
