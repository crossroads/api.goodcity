require 'open-uri'
require 'csv'

namespace :goodcity do
  desc 'Add SWD Organisations'
  task import_swd_organisations: :environment do
    url = "https://www.swd.gov.hk/datagovhk/istb/SWD-GeoInfo-Map.csv"

    CSV.foreach(open(url), encoding: "UTF-16LE:UTF-8", col_sep: "\t", headers: :true, header_converters: :symbol) do |row|
      Organisation.where(gih3_id: row[:gih3_id]).first_or_create do |organisation|
        organisation.name_en              = row[:eng_name],
        organisation.name_zh_tw           = row[:chi_name],
        organisation.description_en       = "",
        organisation.description_zh_tw    = "",
        organisation.registration         = "",
        organisation.website              = row[:website],
        organisation.organisation_type_id = get_organisation_id ,
        organisation.country_id           = get_country_id,
        organisation.district_id          = get_district_id(row[:district])
      end
    end
  end

  def get_organisation_id
    OrganisationType.find_by(name_en: "SWD").try(:id)
  end

  def get_country_id
    Country.find_by(name_en: "Hong Kong").try(:id)
  end

  def get_district_id(district_name)
    District.find_by(name_en: district_name).try(:id) if district_name.present?
  end
end
