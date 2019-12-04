module Goodcity
  class CreateStockitPackage
    
    CONDITIONS = {"N" => "New", "M" => "Lightly Used", "U" => "Heavily Used", "B" => "Broken"}

    def initialize(inventory_number)
      @inventory_number = inventory_number
      @item = nil
      raise "This class is not finished"
    end

    def create!
      @item = get_stockit_item
      create_package
    end

    private

    # Returns the Stockit item
    # Returns nil if no match or more than one match
    def get_stockit_item
      items = Stockit::ItemSync.index(nil, inventory_number: @inventory_number)
      items = JSON.parse(items["items"])
      if items.size == 0
        raise ImportError.new("Stockit found no results for inventory_number #{@inventory_number}")
        items = nil
      elsif items.size > 1
        raise ImportError.new("Stockit found more than one item for inventory_number #{@inventory_number}")
        items = nil
      else
        items.first
      end
    end

    # Given a stockit_id, looks up the Designation
    def get_designation(stockit_id)
      order = Stockit::DesignationSync.show(stockit_id)
      JSON.parse(order["order"])
    end

    def create_package
      stockit_id = @item["id"]
      if Package.where(stockit_id: stockit_id).exists?
        raise ImportError.new("Package with stockit_id #{stockit_id} already exists.")
        return
      end

      @package = Package.new
      @package.notes = value["description"]
      @package.grade = value["grade"]
      @package.pieces = value["pieces"]
      @package.weight = value["weight"]
      @package.case_number = value["case_number"]
      @package.stockit_sent_on = value["sent_on"]
      @package.inventory_number = (value["inventory_number"] || "").gsub(/^x/i, '')
      @package.quantity = value["quantity"].to_i
      @package.received_quantity = @package.quantity
      @package.length = value["length"].to_i.zero? ? "" : value["length"].to_i
      @package.width = value["width"].to_i.zero? ? "" : value["width"].to_i
      @package.height = value["height"].to_i.zero? ? "" : value["height"].to_i
      @package.designation_name = value["designation_code"]
      @package.stockit_id = stockit_id
      @packate.state = nil # only sensible in admin app
      
      # Lookups
      @package.box_id = lookup_box_id(value["box_id"])
      @package.pallet_id = lookup_pallet_id(value["pallet_id"])
      @package.package_type_id = lookup_package_type_id(value["code_id"])
      @package.order_id = lookup_order_id(value["designation_id"]) # need to create orders_packages and order too
      @package.donor_condition_id = lookup_donor_condition_id(value["condition"])
      @package.packages_locations = packages_locations(@package, value["location_id"])
      
      @package.save!

    end

    def lookup_box_id(stockit_id)
      return if stockit_id.nil?
      box_id = Box.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      raise ImportError.new("Box with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit.") if box_id.nil?
      box_id
    end

    def lookup_pallet_id(stockit_id)
      return if stockit_id.nil?
      pallet_id = Pallet.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      raise ImportError.new("Pallet with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit.") if pallet_id.nil?
      pallet_id
    end

    def lookup_package_type_id(stockit_id)
      return if stockit_id.nil?
      package_type_id = Package_type.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      raise ImportError.new("Package_type with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit.") if package_type_id.nil?
      package_type_id
    end

    def lookup_donor_condition_id(stockit_condition)
      return if stockit_condition.nil?
      donor_condition_id = DonorCondition.where(name_en: CONDITIONS[stockit_condition]).limit(1).pluck(:id).first
      raise ImportError.new("DonorCondition with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit.") if donor_condition_id.nil?
      donor_condition_id
    end

    def packages_locations(stockit_location_id)
      return if stockit_location_id.nil?
      location_id = Location.where(stockit_id: stockit_location_id).limit(1).pluck(:id).first
      raise ImportError.new("Location with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit.") if location_id.nil?
      PackagesLocation.where(package_id: @package.id, location_id: location_id).first_or_create!(quantity: @package.quantity)
    end

    def lookup_order_id(stockit_id)
      return if stockit_id.nil?
      order_id = Order.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      raise ImportError.new("Order with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit.") if order_id.nil?
      order_id
    end

    def log(message)
      puts("#{@inventory_number} : #{message}")
    end

    class ImportError < Exception
    end

  end
end


# Package
#"item_id", "state", "received_at", "created_at", "updated_at", "stockit_designated_on", "stockit_designated_by_id", "stockit_sent_by_id", "stockit_moved_on", "stockit_moved_by_id"] 
