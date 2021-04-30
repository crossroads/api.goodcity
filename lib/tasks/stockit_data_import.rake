# frozen_string_literal: true

namespace :goodcity do
  namespace :data do
    task stockit_data_import: :environment do
      # Correct "sent_on" date for "L" orders
      StockitDataImporter.import_sent_dates

      # Map old organisations to new/official organisations
      StockitDataImporter.map_stockit_organisation_to_organisation

      # Import missing shipments for historical reporting
      StockitDataImporter.import_missing_shipments

      # Import additional country fields
      StockitDataImporter.import_additional_country

      # Delete some mistaken orders
      codes = ['S1932I', 'S4468(2)']
      Order.where(code: codes).each do |order|
        if order.packages.any?
          puts "Cannot delete #{order.code} because it has some 'packages'"
        elsif order.goodcity_requests.any?
          puts "Cannot delete #{order.code} because it has some 'goodcity_requests'"
        elsif order.orders_purposes.any?
          puts "Cannot delete #{order.code} because it has some 'orders_purposes'"
        elsif order.purposes.any?
          puts "Cannot delete #{order.code} because it has some 'purposes'"
        elsif order.orders_packages.any?
          puts "Cannot delete #{order.code} because it has some 'orders_packages'"
        elsif order.messages.any?
          puts "Cannot delete #{order.code} because it has some 'messages'"
        elsif order.subscriptions.any?
          puts "Cannot delete #{order.code} because it has some 'subscriptions'"
        elsif order.orders_process_checklists.any?
          puts "Cannot delete #{order.code} because it has some 'orders_process_checklists'"
        elsif order.process_checklists.any?
          puts "Cannot delete #{order.code} because it has some 'process_checklists'"
        elseif order.order_transport.present?
          puts "Cannot delete #{order.code} because it has an 'order_transport'"
        else
          order.destroy
          puts "Destroyed #{order.code}"
        end
      end
      puts "Completed task."
      
    end
  end
end
