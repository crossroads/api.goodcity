namespace :stockit do
  desc 'Load all item details from Stockit'
  task add_stockit_items: :environment do
    PaperTrail.enabled = false
    offset = 0
    per_page = 1000
    count = 1
    pages = 267 # hard coded but that's currently how many pages of 1000 we need to retreive
    @failed = {} # hash of failed stockit_ids
    at_exit do
      if @failed.any?
        puts "#{@failed.count} failed Stockit items (stockit_id)"
        @failed.each {|id, error| puts "#{id} : #{error}"}
      else
        puts "All items succeeded."
      end
    end

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

            package.order_id = lookup_order_id(value["designation_id"])
            package.donor_condition_id = lookup_donor_condition_id(value["condition"])
            package.packages_locations = packages_locations(package, value["location_id"])
            package.package_type_id = lookup_package_type_id(value["code_id"])
            package.box_id = lookup_box_id(value["box_id"])
            package.pallet_id = lookup_pallet_id(value["pallet_id"])
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

  # lookup hash of DonorCondition condition -> id
  def lookup_donor_condition_id(condition)
    value = case condition
      when "N" then "New"
      when "M" then "Lightly Used"
      when "U" then "Heavily Used"
      when "B" then "Broken"
    end
    @condition ||=
      begin
        h = {}
        DonorCondition.select("id, name_en").find_each{|obj| h[obj.name_en] = obj.id}
        h
      end
    @condition[value]
  end

  # lookup hash of Box stockit_id -> id
  def lookup_box_id(stockit_id)
    @boxes ||= begin
      h = {}
      Box.select("id, stockit_id").find_each{|obj| h[obj.stockit_id] = obj.id}
      h
    end
    @boxes[stockit_id]
  end

  # lookup hash of Pallet stockit_id -> id
  def lookup_pallet_id(stockit_id)
    @pallets ||= begin
      h = {}
      Pallet.select("id, stockit_id").find_each{|obj| h[obj.stockit_id] = obj.id}
      h
    end
    @pallets[stockit_id]
  end

  # lookup hash of PackageType stockit_id -> id
  def lookup_package_type_id(stockit_id)
    @package_types ||= begin
      h = {}
      PackageType.select("id, stockit_id").find_each{|obj| h[obj.stockit_id] = obj.id}
      h
    end
    @package_types[stockit_id]
  end

  # lookup hash of Orders stockit_id -> id
  def lookup_order_id(stockit_id)
    @orders ||= begin
      h = {}
      Order.select("id, stockit_id, state").find_each{|obj| h[obj.stockit_id] = obj.id}
      h
    end
    @orders[stockit_id]
  end

  # lookup hash of Locations stockit_id -> id
  def lookup_location_id(stockit_id)
    @locations ||= begin
      h = {}
      Location.select("id, stockit_id").find_each{|obj| h[obj.stockit_id] = obj.id}
      h
    end
    @locations[stockit_id]
  end

  # lookup hash of PackagesLocations indexed by package and location_id
  # returns the equivalent of first_or_initialize
  def lookup_packages_location(package_id, location_id)
    @packages_locations ||= begin
      h = {}
      PackagesLocation.find_each{|obj| h["#{obj.package_id}:#{obj.location_id}"] = obj}
      h
    end
    key = "#{package_id}:#{location_id}"
    @packages_locations[key] || PackagesLocation.new(package_id: package_id, location_id: location_id)
  end

  def packages_locations(package, stockit_location_id)
    quantity = package.quantity
    location_id = lookup_location_id(stockit_location_id)
    return [] unless (location_id and quantity)
    record = lookup_packages_location(package.id, location_id)
    record.quantity = quantity
    [record]
  end

  def package_designation(designation_id)
    Order.find_by(stockit_id: designation_id) if designation_id.present?
  end




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
            package.update_column(:order_id, lookup_order_id(value["designation_id"])) if package
          end
        end
      else
        break
      end
    end
  end

end
