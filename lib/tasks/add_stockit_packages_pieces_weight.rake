namespace :stockit do
  task add_stockit_packages_pieces_weight: :environment do
    offset = 0
    per_page = 1000
    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index
      offset += per_page
      stockit_items = JSON.parse(items_json["items"])
      bar = RakeProgressbar.new(stockit_items.size)
      next unless stockit_items.present?

      stockit_items.each do |value|
        bar.inc
        next unless value["id"].present?

        package = Package.find_by(stockit_id: value["id"])
        package&.update_attributes(pieces: value["pieces"], weight: value["weight"])
      end
      bar.finished
      break
    end
  end
end
