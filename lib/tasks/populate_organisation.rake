require 'sidekiq/api'
#use 'rake populate_organisation:organisation' to create or update organisation details
namespace :populate_organisation do
  task organisation:  :environment do
    organisation_hash = {
      "name_en" => "name_en",
      "name_zh_tw" => "name_zh",
      "website" => "url",
    }
    #set organisation_type
    organisation_type_name = "NGO"
    organisation_type = OrganisationType.find_by_name_en(organisation_type_name) || OrganisationType.create(name_en: organisation_type_name ,name_zh_tw: organisation_type_name ,category_en: organisation_type_name  , category_zh_tw: organisation_type_name)

    #set country
    country_name = "China - Hong Kong (Special Administrative Region)"
    country_code = "HKG"
    country_region = "Asia"

    #for job
    stockit_id = StockitCountryAddJob.perform_now(country_name, country_name, country_code, country_region)
    country = Country.find_by_name_en(stockit_id)|| Country.create(name_en: country_name ,name_zh_tw: country_name)

    begin
      file = Nestful.get("https://goodcitystorage.blob.core.windows.net/public/s88-orgs.json").response.body
    rescue Exception => e
      Airbrake.notify(e, error_class: "populate_organisation", error_message: "Organisation File Error")
    end

    # file = File.read('app/assets/organisation.json')
    if (file.present?)
      JSON.parse(file).each do |data|
        organisation_hash =  organisation_hash.keep_if { |k, v| data.key? v }
        organisation = Organisation.find_by(registration: data['org_id']) || Organisation.new(registration: data['org_id'], organisation_type: organisation_type, country: country)
          organisation_hash.each do |organisation_column, data_key|
            unless(organisation.try(organisation_column) == data[data_key])
              organisation[organisation_column.to_sym] = data[data_key]
            end
          end
         organisation.save
      end
    end
  end
end
