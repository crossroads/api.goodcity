module Goodcity
  class OrganisationPopulator

    ORGANISATION_TYPE_NAME = "NGO"
    COUNTRY_NAME_EN = "China - Hong Kong (Special Administrative Region)"
    URL = "https://goodcitystorage.blob.core.windows.net/public/s88-orgs.json"
    ORGANISATION_MAPPING = {
      "name_en" => "name_en",
      "name_zh_tw" => "name_zh",
      "website" => "url",
    }

    def self.run
      new.run
    end

    def run
      # payload = File.new('spec/fixtures/organisation.json')
      JSON.parse(payload, object_class: OpenStruct).each do |data|
        organisation_fields_mapping =  ORGANISATION_MAPPING.keep_if { |k, v| data.key? v }
        debugger
        organisation = get_organisation(data['org_id']) || build_organisation(data['org_id'])
        ORGANISATION_MAPPING.each do |organisation_column, data_key|
            organisation[organisation_column.to_sym] = data[data_key]
        end
        organisation.save
      end
    end

    private

    def payload
      Nestful.get(URL).response.body || "{}"
    end

    def organisation_type
      @organisation_type ||= OrganisationType.find_or_create_by(name_en: ORGANISATION_TYPE_NAME)
    end

    def get_organisation(org_id)
      Organisation.find_by(registration: org_id)
    end

    def build_organisation (org_id)
      Organisation.new(registration: org_id,
        organisation_type: organisation_type,
        country: default_country)
    end

    def default_country
      @default_country ||= Country.find_by_name_en(COUNTRY_NAME_EN)
    end

  end
end
