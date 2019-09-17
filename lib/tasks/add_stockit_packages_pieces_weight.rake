namespace :stockit do
  task add_stockit_packages_pieces_weight: :environment do
    offset = 0
    per_page = 1000
    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index
      offset += per_page
      stockit_items = JSON.parse(items_json["items"])
      bar = RakeProgressbar.new(stockit_items.size)
      break if stockit_items.blank?

      stockit_items.each do |item|
        bar.inc
        package = Package.find_by(stockit_id: item["id"]) if item["id"]
        package&.update_columns(pieces: item["pieces"], weight: item["weight"])
      end
      bar.finished
    end
  end
end
