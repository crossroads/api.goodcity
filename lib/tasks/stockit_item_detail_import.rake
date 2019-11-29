#rake stockit:add_stockit_items_detail_to_packages
require "goodcity/detail_factory"
require "goodcity/rake_logger"

namespace :stockit do
  desc 'Import data from stockit for item detail and save it in package'
  task add_stockit_items_detail_to_packages: :environment do
    log = Goodcity::RakeLogger.new("add_stockit_items_detail_to_packages")
    count = 0
    ["electricals", "computers", "computer_accessories"].each do |table_name|
      offset = 0
      per_page = 10000000
      loop do
        items_json = Stockit::ItemSync.index_with_detail(offset, per_page, table_name)
        offset += per_page
        stockit_items = JSON.parse(items_json["items"])
        break if stockit_items.blank?
        stockit_items.each do |item|
          item_id = item["package_id"].presence
          package = Package.find_by(stockit_id: item["package_id"]) if item_id
          begin
            is_package_updated = Goodcity::DetailFactory.new(item, package).run
          rescue => exception
            log.error("package: #{package.id}, stockit_item: #{item_id} #{exception.message}")
          end
          if is_package_updated
            print "."
            count += 1
          end
        end
      end
    end
    puts "\n#{count} packages updated with new details from stockit"
    log.info("#{count} packages updated with new details from stockit")
  end
end
