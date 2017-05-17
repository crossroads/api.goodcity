namespace :stockit do
  desc 'Load all item details from Stockit'
  task add_stockit_items: :environment do
    PaperTrail.enabled = false

    offset = 0
    per_page = 1000
    count = 1
    pages = 267 # hard coded but that's current how many pages of 1000 we need to retreive
    @failed = {} # hash of failed stockit_ids

    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index
      offset = offset + per_page
      stockit_items = JSON.parse(items_json["items"])
      if stockit_items.present?
        puts "Currently on page #{count} / #{pages}"; count += 1
        bar = RakeProgressbar.new(stockit_items.size)
        stockit_items.each do |value|
          bar.inc
          stockit_id = value["id"]

          if stockit_id.present?
            package = Package.where(stockit_id: stockit_id).first_or_initialize
            package.notes = value["description"]
            package.grade = value["grade"]
            package.stockit_sent_on = value["sent_on"]
            package.inventory_number = (value["inventory_number"] || "").gsub(/^x/i, '')

            package.quantity = value["quantity"].to_i
            package.received_quantity = package.quantity

            package.length = value["length"].to_i.zero? ? "" : value["length"].to_i
            package.width = value["width"].to_i.zero? ? "" : value["width"].to_i
            package.height = value["height"].to_i.zero? ? "" : value["height"].to_i
            package.designation_name = value["designation_code"]

            package.order = package_designation(value["designation_id"])
            package.donor_condition = package_condition(value["condition"])
            package.packages_locations = packages_locations(package, value["location_id"])
            package.package_type = package_type_record(value["code_id"])
            package.box = box_record(value["box_id"])
            package.pallet = pallet_record(value["pallet_id"])
            begin
              package.save!
            rescue ActiveRecord::RecordInvalid => e
              @failed.merge!(stockit_id => e)
            end
          end
        end
        bar.finished
      else
        break
      end
    end
  end

  at_exit do
    if @failed.any?
      puts "#{@failed.count} failed Stockit items (stockit_id)"
      @failed.each {|id, error| puts "#{id} : #{error}"}
    else
      puts "All items succeeded."
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

  def packages_locations(package, stockit_location_id)
    quantity = package.quantity
    location_id = Location.find_by(stockit_id: stockit_location_id).try(:id)
    return [] unless (location_id and quantity)
    record = package.packages_locations.where(location_id: location_id).first_or_initialize
    record.quantity = quantity
    [record]
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
