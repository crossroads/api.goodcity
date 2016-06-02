namespace :goodcity do

  # rake goodcity:add_stockit_pallets_boxes
  desc 'Load pallet details from stockit'
  task add_stockit_pallets_boxes: :environment do
    Pallet.delete_all

    pallets_json = Stockit::PalletSync.index
    stockit_pallets = JSON.parse(pallets_json["pallets"])

    if stockit_pallets
      stockit_pallets.each do |value|
        pallet = Pallet.where(
          pallet_number: value["pallet_number"],
          description: value["description"],
          comments: value["comments"],
          stockit_id: value["id"]
        ).first_or_create
      end
    end

    Box.delete_all

    boxes_json = Stockit::BoxSync.index
    stockit_boxes = JSON.parse(boxes_json["boxes"])

    if stockit_boxes
      stockit_boxes.each do |value|
        pallet_id = Pallet.find_by(stockit_id: value["pallet_id"]).try(:id)

        box = Box.where(
          box_number: value["box_number"],
          description: value["description"],
          comments: value["comments"],
          stockit_id: value["id"],
          pallet_id: pallet_id
        ).first_or_create
      end
    end
  end
end
