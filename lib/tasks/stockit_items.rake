namespace :stockit do

  desc 'Load all item details from Stockit'
  task add_stockit_items: :environment do

    offset = 0
    per_page = 1000

    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index
      offset = offset + per_page
      stockit_items = JSON.parse(items_json["items"])

      if stockit_items.present?
        stockit_items.each do |value|
          inventory_number = (value["inventory_number"] || "").gsub(/^x/i, '')

          if inventory_number.present?
            package = Package.where(inventory_number: inventory_number).first_or_initialize

            package.stockit_id = value["id"]
            package.notes = value["description"]
            package.grade = value["grade"]
            package.stockit_sent_on = value["sent_on"]

            package.quantity = value["quantity"].to_i.zero? ? 1 : value["quantity"].to_i

            package.length = value["length"].to_i.zero? ? "" : value["length"].to_i
            package.width = value["width"].to_i.zero? ? "" : value["width"].to_i
            package.height = value["height"].to_i.zero? ? "" : value["height"].to_i

            package.order = package_designation(value["designation_id"])
            package.designation_name = value["designation_code"]
            package.donor_condition = package_condition(value["condition"])
            package.locations << package_location(value["location_id"])
            package.package_type = package_type_record(value["code_id"])
            package.box = box_record(value["box_id"])
            package.pallet = pallet_record(value["pallet_id"])
            package.save
          end
        end
      else
        break
      end
    end
  end

  def box_record(box_id)
    Box.find_by(stockit_id: box_id) if box_id.present?
  end

  def pallet_record(pallet_id)
    Pallet.find_by(stockit_id: pallet_id) if pallet_id.present?
  end

  def package_condition(condition)
    value = case condition
      when "N" then "New"
      when "M" then "Lightly Used"
      when "U" then "Heavily Used"
      when "B" then "Broken"
      end
    DonorCondition.find_by(name_en: value) if value.present?
  end

  def package_location(location_id)
    Location.find_by(stockit_id: location_id) if location_id.present?
  end

  def package_type_record(code_id)
    PackageType.find_by(stockit_id: code_id) if code_id.present?
  end

  def package_designation(designation_id)
    Order.find_by(stockit_id: designation_id) if designation_id.present?
  end


  # rake goodcity:update_stockit_items
  desc 'Update stockit designation of items'
  task update_stockit_items: :environment do

    offset = 0
    per_page = 1000

    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index
      offset = offset + per_page
      stockit_items = JSON.parse(items_json["items"])

      if stockit_items.present?
        stockit_items.each do |value|
          if value["id"].present?
            package = Package.find_by(stockit_id: value["id"])
            if package
              package.update_column(:order_id, package_designation(value["designation_id"]))
            end
          end
        end
      else
        break
      end
    end
  end

end
