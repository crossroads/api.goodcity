#rake stockit:add_stockit_items_detail_to_packages
require "goodcity/detail_factory"
namespace :stockit do
  desc 'Import data from stockit for item detail and save it in package'
  task add_stockit_items_detail_to_packages: :environment do
    offset = 0
    per_page = 1000

    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index_with_detail
      offset += per_page
      stockit_items = JSON.parse(items_json["items"])
      bar = RakeProgressbar.new(stockit_items.size)
      break if stockit_items.blank?

      stockit_items.each do |item|
        bar.inc
        package = Package.find_by(stockit_id: item["id"]) if item["id"]
        next unless package

        Goodcity::DetailFactory.new(item, package).run
      end
    end
    bar.finished
  end
end
