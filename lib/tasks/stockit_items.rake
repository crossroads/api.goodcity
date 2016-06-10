namespace :goodcity do

  # rake goodcity:add_stockit_items
  desc 'Load all item details from stockit'
  task add_stockit_items: :environment do
    items_json = Stockit::ItemSync.index
    stockit_items = JSON.parse(items_json["items"])

    if stockit_items
      stockit_items.each do |value|
        package = Package.where(inventory_number: value["inventory_number"]).first_or_initialize
        package.stockit_id = value["id"]
        package.quantity = value["quantity"]
        package.notes = value["description"]
        package.length = value["length"]
        package.width = value["width"]
        package.height = value["height"]
        package.grade = value["grade"]
        package.stockit_sent_on = value["sent_on"]
        package.stockit_designation = package_designation(value["designation_id"])
        package.designation_name = value["designation_code"]
        package.donor_condition = package_condition(value["condition"])
        package.location = package_location(value["location_id"])
        package.package_type = package_type_record(value["code_id"])
        package.box = box_record(value["box_id"])
        package.pallet = pallet_record(value["pallet_id"])
        package.save
      end
    end
  end

  def box_record(box_id)
    Box.find_by(stockit_id: box_id)
  end

  def pallet_record(pallet_id)
    Pallet.find_by(stockit_id: pallet_id)
  end

  def package_condition(condition)
    value = case condition
      when "N" then "New"
      when "M" then "Lightly Used"
      when "U" then "Heavily Used"
      when "B" then "Broken"
      end
    DonorCondition.find_by(name_en: value)
  end

  def package_location(location_id)
    Location.find_by(stockit_id: location_id)
  end

  def package_type_record(code_id)
    PackageType.find_by(stockit_id: code_id)
  end

  def package_designation(designation_id)
    StockitDesignation.find_by(stockit_id: designation_id)
  end
end
