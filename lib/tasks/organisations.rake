require "goodcity/organisation_populator"

namespace :goodcity do

  # use 'rake goodcity:populate_organisations' to create or update organisation details from HK IRD database
  # rake goodcity:populate_organisations
  task populate_organisations:  :environment do
    Goodcity::OrganisationPopulator.run
  end

  # rake goodcity:add_organisations
  desc 'Add Organisations list'
  task add_organisations: :environment do
    organisations = YAML.load_file("#{Rails.root}/db/organisations.yml")
    organisations.each do |key, value|
      organisation = Organisation.where(
        name_en: value[:name_en],
        name_zh_tw: value[:name_zh_tw],
        description_en: value[:description_en],
        description_zh_tw: value[:description_zh_tw],
        registration: value[:registration],
        website: value[:website],
        organisation_type_id: organisation_record(value[:organisation_name]),
        country_id: country_record(value[:country_name]),
        district_id: district_record(value[:district_name])
      ).first_or_create
    end
  end

  def organisation_record(organisation_name)
    OrganisationType.find_by(name: organisation_name) if organisation_name.present?
  end

  def country_record(country_name)
    Country.find_by(name: country_name) if country_name.present?
  end

  def district_record(district_name)
    District.find_by(name: district_name) if district_name.present?
  end

end
