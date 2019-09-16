namespace :stockit do
  task add_stockit_packages_pieces_weight: :environment do
    offset = 0
    per_page = 1000
    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index
      offset = offset + per_page
      stockit_items = JSON.parse(items_json["items"])
      bar = RakeProgressbar.new(stockit_items.size)
      if stockit_items.present?
        stockit_items.each do |value|
          bar.inc
          if value["id"].present?
            package = Package.find_by(stockit_id: value["id"])
            package.update_attributes(pieces: value["pieces"], weight: value["weight"]) if package
          end
        end
        bar.finished
      else
        break
      end
    end
  end
end
