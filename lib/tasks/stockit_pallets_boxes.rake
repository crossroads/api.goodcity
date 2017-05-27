namespace :stockit do

  desc 'Load pallet details from stockit'
  task add_stockit_pallets_boxes: :environment do

    pallets_json = Stockit::PalletSync.index
    stockit_pallets = JSON.parse(pallets_json["pallets"]) || []
    stockit_pallets.each do |value|
      pallet = Pallet.where(stockit_id: value["id"]).first_or_initialize
      pallet.pallet_number = value["pallet_number"]
      pallet.description = value["description"]
      pallet.comments = value["comments"]
      pallet.save!
    end
  
    boxes_json = Stockit::BoxSync.index
    stockit_boxes = JSON.parse(boxes_json["boxes"]) || []
    stockit_boxes.each do |value|
      box = Box.where(stockit_id: value["id"]).first_or_initialize
      box.box_number = value["box_number"]
      box.description = value["description"]
      box.comments = value["comments"]
      box.pallet_id = Pallet.find_by(stockit_id: value["pallet_id"]).try(:id)
      box.save!
    end

  end
end
