class StockitCountryAddJob < ActiveJob::Base
  queue_as :default

  def perform(country_name_en, country_name_zh, country_code, country_region)
    response = Stockit::CountrySync.create(country_name_en, country_name_zh, country_code, country_region)

    if response && (errors = response["errors"] || response[:errors])
      log_text = "Country: #{country_name_en} "
      errors.each{ |attribute, error| log_text += " #{attribute}: #{error}" }
      logger.error log_text
    end
    response["country_id"]
  end
end
