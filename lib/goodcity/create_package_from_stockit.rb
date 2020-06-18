# Given an inventory number, gets the details from Stockit and creates it in GoodCity
#   this inventory_number must NOT already exist in GoodCity.
#   Use in conjunction with PackageDestroyer
#

module Goodcity
  class CreatePackageFromStockit

    def initialize(inventory_number)
      @inventory_number = inventory_number
      @inventory_number = "X#{@inventory_number}" if @inventory_number =~ /^[0-9]+/
      @stockit_item = nil
    end

    def create
      @stockit_item = get_stockit_item
      create_package_from_stockit_item(@stockit_item) if @stockit_item
    end

    def self.create(inventory_number)
      new(inventory_number).create
    end

    private

    # Returns the Stockit item
    # Raises error if no match or more than one match
    def get_stockit_item
      items = Stockit::ItemSync.index(@inventory_number, 0, 10)
      items = JSON.parse(items["items"] || "{}")
      if items.size == 0
        log([@inventory_number, "Stockit found no results for this inventory_number"])
        items = nil
      elsif items.size > 1
        log([@inventory_number, "Stockit returned more than one item for this inventory_number"])
        items = nil
      else
        items.first
      end
    end

    # Given a stockit_id, looks up the Designation
    # def get_designation(stockit_id)
    #   order = Stockit::DesignationSync.show(stockit_id)
    #   JSON.parse(order["order"])
    # end

    # Pass in the details from Stockit and create a package in GoodCity
    def create_package_from_stockit_item(stockit_item)
      @package = Package.where(inventory_number: @inventory_number)
      if @package.size > 0
        log([@inventory_number, "A package with this inventory_number already exists. No action taken."])
        return
      end
      
      ActiveRecord::Base.transaction do
        @package = Package.new
              
        @package.stockit_id = stockit_item["id"]
        @package.state = "received"
        @package.received_quantity = stockit_item["quantity"].to_i
        @package.grade = stockit_item["grade"]
        @package.pieces = stockit_item["pieces"]
        @package.weight = stockit_item["weight"]
        @package.case_number = stockit_item["case_number"]
        @package.stockit_sent_on = stockit_item["sent_on"]
        @package.inventory_number = (stockit_item["inventory_number"] || "").gsub(/^X/i, '')
        @package.length = stockit_item["length"].to_i.zero? ? nil : stockit_item["length"].to_i
        @package.width = stockit_item["width"].to_i.zero? ? nil : stockit_item["width"].to_i
        @package.height = stockit_item["height"].to_i.zero? ? nil : stockit_item["height"].to_i
        @package.comment = stockit_item["description"]

        # Lookups
        @package.package_type_id = lookup_package_type_id(stockit_item["code_id"])
        @package.box_id = lookup_box_id(stockit_item["box_id"])
        @package.pallet_id = lookup_pallet_id(stockit_item["pallet_id"])
        @package.donor_condition_id = lookup_donor_condition(stockit_item["condition"])
        
        @package.save!

        location = Location.where(stockit_id: stockit_item['location_id']).first
        Package::Operations.inventorize(@package, location)

        # Designate / Dispatch order
        if (order_code = stockit_item['designation_code']).present?
          order = Order.where(code: order_code).first
          old_state = nil
          if !Order::ACTIVE_STATES.include?(order.state)
            old_state = order.state
            order.update_column(:state, 'dispatching')
          end
          Package::Operations.designate(@package, quantity: @package.quantity, to_order: order)

          if package.stockit_sent_on.present?
            Package::Operations.dispatch(@package.orders_packages.first, quantity: @package.quantity, from_location: location)
          end
          order.update_column(:state, old_state) if old_state.present?

        end

        @package

        byebug
        raise ActiveRecord::Rollback

      end # transaction

    end

    def lookup_box_id(stockit_id)
      return if stockit_id.nil?
      box_id = Box.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      log([stockit_id, "Box with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit."]) if box_id.nil?
      box_id
    end

    def lookup_pallet_id(stockit_id)
      return if stockit_id.nil?
      pallet_id = Pallet.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      log([stockit_id, "Pallet with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit."]) if pallet_id.nil?
      pallet_id
    end

    def lookup_package_type_id(stockit_id)
      return if stockit_id.nil?
      package_type_id = PackageType.where(stockit_id: stockit_id).limit(1).pluck(:id).first
      log([stockit_id, "Package_type with stockit_id #{stockit_id} not found in GoodCity but exists in Stockit."]) if package_type_id.nil?
      package_type_id
    end

    def lookup_donor_condition(stockit_condition)
        case stockit_condition
        when "N" then 1
        when "M" then 5
        when "U" then 3
        when "B" then 4
        end
      end
    end

    # log([inventory_number, "Message about this number"])
    def log(details)
      id, message = details
      puts("#{id},#{message}")
    end

    class ImportError < Exception
    end

  end
end


# Package
#   "item_id", "state", "received_at", "created_at", "updated_at",
#   "stockit_designated_on", "stockit_designated_by_id", "stockit_sent_by_id",
#   "stockit_moved_on", "stockit_moved_by_id"
