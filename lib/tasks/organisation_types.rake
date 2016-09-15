namespace :goodcity do

  # rake goodcity:add_organisation_types
  desc 'Add Organisation Type list'
  task add_organisation_types: :environment do
    organisation_types = YAML.load_file("#{Rails.root}/db/organisation_types.yml")
    organisation_types.each do |key, value|
      organisation_type = OrganisationType.where(
        name_en: value[:name_en],
        name_zh: value[:name_zh],
        category_en: value[:category_en],
        category_zh: value[:category_zh]
      ).first_or_create
    end
  end

end
