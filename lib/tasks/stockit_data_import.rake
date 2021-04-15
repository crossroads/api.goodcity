# frozen_string_literal: true

namespace :goodcity do
  namespace :data do
    task stockit_data_import: :environment do
      # Correct "sent_on" date for "L" orders
      StockitDataImporter.import_sent_dates

      # Map old organisations to new/official organisations
      # StockitDataImporter.map_stockit_organisation_to_organisation

      # Import missing shipments for historical reporting
      StockitDataImporter.import_missing_shipments

      # Import additional country fields
      StockitDataImporter.import_additional_country

      # Delete some mistaken orders
      codes = ['S1932I', 'S4468(2)']
      Order.where(code: codes).destroy_all
      puts "****** Removed mistaken #{codes}"
    end
  end
end
