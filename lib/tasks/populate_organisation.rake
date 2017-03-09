#use 'rake populate_organisation:organisation' to create or update organisation details

ORGANISATION_TYPE_NAME = "NGO"
COUNTRY_NAME_EN = "China - Hong Kong (Special Administrative Region)"
URL = "https://goodcitystorage.blob.core.windows.net/public/s88-orgs.json"
ORGANISATION_MAPPING = {
  "name_en" => "name_en",
  "name_zh_tw" => "name_zh",
  "website" => "url",
}

namespace :populate_organisation do
  task organisation:  :environment do
    organisation_type = get_organisation_type
    country = Country.find_by_name_en(COUNTRY_NAME_EN)

    begin
      file = Nestful.get(URL).response.body
    rescue Exception => e
      Airbrake.notify(e, error_class: "populate_organisation", error_message: "Organisation File Error")
    end

    # file = File.read('app/assets/organisation.json')
    if (file.present?)
      JSON.parse(file).each do |data|
        organisation_fields_mapping =  ORGANISATION_MAPPING.keep_if { |k, v| data.key? v }
        organisation = get_organisation(data) || build_organisation(data, organisation_type, country)
        puts organisation
        puts data
        organisation_fields_mapping.each do |organisation_column, data_key|
          unless(organisation.try(organisation_column) == data[data_key])
            organisation[organisation_column.to_sym] = data[data_key]
          end
        end
        organisation.save
      end
    end
  end

  def get_organisation_type
    OrganisationType.find_by_name_en(ORGANISATION_TYPE_NAME) || OrganisationType.create(name_en: ORGANISATION_TYPE_NAME)
  end

  def get_organisation(data)
    Organisation.find_by(registration: data['org_id'])
  end

  def build_organisation (data, organisation_type, country)
    Organisation.new(registration: data['org_id'],
     organisation_type: organisation_type,
     country: country)
  end
end
