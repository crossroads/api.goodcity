namespace :goodcity do

  # rake goodcity:add_organisation_types
  desc 'Add Organisation Type list'
  task add_organisation_types: :environment do
    organisation_types = YAML.load_file("#{Rails.root}/db/organisation_types.yml")
    organisation_types.each do |_key, value|
      OrganisationType.where(
        name_en: value[:name_en],
        name_zh_tw: value[:name_zh_tw],
        category_en: value[:category_en],
        category_zh_tw: value[:category_zh_tw]
      ).first_or_create
    end
  end

end
