require "goodcity/rake_logger"

require 'open-uri'
require 'csv'

namespace :goodcity do
  desc 'Add SWD Organisations'

  DISTRICT_NAME_CSV_AND_DB_MAPPING = {
    "EASTERN AND WAN CHAI" => "Wan Chai",
    "KOWLOON CITY AND YAU TSIM MONG" => "kowloon City",
    "TAI PO AND NORTH" => "Taipo",
    "TSUEN WAN AND KWAI TSING" => "Tsuen Wan",
    "SHATIN" => "Sha Tin",
  }

  task import_swd_organisations: :environment do
    log = Goodcity::RakeLogger.new("import_swd_organisations")
    url = "https://www.swd.gov.hk/datagovhk/istb/SWD-GeoInfo-Map.csv"

    success_count = error_count = 0

    CSV.foreach(open(url), encoding: "UTF-16LE:UTF-8", col_sep: "\t", headers: :true, header_converters: :symbol) do |row|
      begin
        organisation = Organisation.where(gih3_id: row[:gih3_id]).first_or_create
        organisation.name_en              = row[:eng_name]
        organisation.name_zh_tw           = row[:chi_name]
        organisation.description_en       = ""
        organisation.description_zh_tw    = ""
        organisation.registration         = ""
        organisation.website              = row[:website]
        organisation.organisation_type_id = get_organisation_id
        organisation.country_id           = get_country_id
        organisation.district_id          = get_district_id(row[:district])
        if organisation.save
          success_count += 1
        else
          log.error "Organisation with Id #{organisation.id} didn't save error: #{organisation.errors.full_messages}"
          error_count += 1
        end
      rescue Exception => e
        log.error "organisation gih3_id: #{row[:gih3_id]} Error = (#{e.message})"
        error_count += 1
      end
    end
    log.info("\n\t Total number of organisation updated =#{success_count} and error occurred = #{error_count}")
  end

  def get_organisation_id
    @org_id ||= OrganisationType.find_by(name_en: "SWD").try(:id)
  end

  def get_country_id
    @country_id ||= Country.find_by(name_en: "China - Hong Kong (Special Administrative Region)").try(:id)
  end

  def get_district_id(district_name)
    if district_name.present?
      get_exact_matching_district_id(district_name) || get_district_id_with_csv_db_mapping(district_name)
    end
  end

  def get_district_id_with_csv_db_mapping(district_name)
    District.find_by(name_en: DISTRICT_NAME_CSV_AND_DB_MAPPING[district_name]).try(:id)
  end

  def get_exact_matching_district_id(district_name)
    District.find_by(name_en: district_name).try(:id)
  end
end
