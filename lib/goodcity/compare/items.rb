require 'goodcity/compare/base'

#
# Usage:
# > Goodcity::Compare::Items.run
#
# Generates two huge SQL datasets for Stockit Items and Goodcity packages
#   and determines how they differ
module Goodcity
  class Compare

    class Items < Base

      def stockit_sql
        # items.created_at AS created_at,
        # date_trunc('hour', items.updated_at) as updated_at,
        # moved_by AS stockit_moved_by_id, designated_by AS stockit_designated_by_id, sent_by AS stockit_sent_by_id
        # moved_on AS stockit_moved_on, designated_on AS stockit_designated_on
        # organisations.name, contacts.first_name, contacts.last_name
        # case_number, grade, items.description AS notes,
        # CASE condition WHEN 'N' THEN 1 WHEN 'U' THEN 3 WHEN 'M' THEN 2 WHEN 'B' THEN 4 END AS donor_condition_id
        # p.weight AS weight, p.width AS width, p.length AS length, p.height AS height, pieces, pallet_id, items.box_id,
        <<-SQL
        SELECT items.id as stockit_id,
          inventory_number, quantity as received_quantity, codes.code AS package_code, designations.code,
          COALESCE(locations.building, '') || COALESCE(locations.area, '') AS location,
          items.sent_on AS sent_on
        FROM items
        LEFT JOIN (
          SELECT DISTINCT ON (item_id) * FROM packages
        ) AS p on items.id = p.item_id
        LEFT JOIN codes ON codes.id = items.code_id
        LEFT JOIN locations ON locations.id = items.location_id
        LEFT JOIN designations ON designations.id = items.designation_id
        LEFT JOIN organisations ON designations.organisation_id = organisations.id
        LEFT JOIN contacts ON designations.contact_id = contacts.id
        ORDER BY items.id ASC
        SQL
      end

      def goodcity_sql
        # packages.created_at AS created_at,
        # to_char(date_trunc('hour', packages.created_at), 'YYYY-MM-DD HH24:MI:SS') as created_at,
        # to_char(date_trunc('hour', packages.updated_at), 'YYYY-MM-DD HH24:MI:SS') as updated_at,
        # stockit_moved_by_id, stockit_designated_by_id, stockit_sent_by_id
        # stockit_moved_on, stockit_designated_on
        # stockit_organisations.name, stockit_contacts.first_name, stockit_contacts.last_name,
        # case_number, grade, notes, weight, width, length, height, pieces,
        # pallets.stockit_id AS pallet_id, boxes.stockit_id AS box_id
        # donor_condition_id,
        <<-SQL
        SELECT packages.stockit_id, 
          inventory_number, received_quantity, package_types.code AS package_code, orders.code,
          COALESCE(locations.building, '') || COALESCE(locations.area, '') AS location,
          ops.sent_on
        FROM packages
        LEFT JOIN (
          SELECT DISTINCT ON (package_id) * FROM packages_locations
        ) AS pls ON packages.id=pls.package_id
        LEFT JOIN locations ON locations.id = pls.location_id
        LEFT JOIN (
          SELECT DISTINCT ON (package_id) * FROM orders_packages
        ) AS ops ON packages.id=ops.package_id
        LEFT JOIN orders ON orders.id = ops.order_id
        LEFT JOIN donor_conditions ON donor_conditions.id = packages.donor_condition_id
        LEFT JOIN package_types ON package_types.id = packages.package_type_id
        LEFT JOIN stockit_organisations ON stockit_organisations.id = orders.stockit_organisation_id
        LEFT JOIN stockit_contacts ON stockit_contacts.id = orders.stockit_contact_id
        LEFT JOIN boxes ON boxes.id = packages.box_id
        LEFT JOIN pallets ON pallets.id = packages.pallet_id
        WHERE packages.stockit_id IS NOT NULL
        ORDER BY packages.stockit_id ASC
        SQL
      end

      # Handle case where X numbers are stored differently
      #   and that location 'Dispatched' in Stockit is equal to nil location in GoodCity
      # Note: Stockit is always left hand side (a) and GoodCity is always right hand side (b)
      def diff(a,b)
        (a["inventory_number"] || "").gsub!(/^X/, "")
        b["location"] = "Dispatched" if (a["location"] == "Dispatched" && b["location"] == "")
        super
      end
      
      # For some columns, we can make automatic decisions about how to fix it.
      # This generally involves favouring Stockit if the Goodcity side is blank
      def auto_fix
        @auto_fix_counter = 0
        @missing_orders_package_record_count = 0
        @missing_order_or_package = 0
        @differences.each do |stockit_id, diffs|
          raise NilStockitIdError if stockit_id.blank? # failsafe
          auto_fix_single_columns(stockit_id, diffs)
          # auto_fix_box_id(stockit_id, diffs)
          # auto_fix_pallet_id(stockit_id, diffs)
          # auto_fix_dispatched(stockit_id, diffs) # DONE
          auto_fix_quantity(stockit_id, diffs)
          auto_fix_locations(stockit_id, diffs)
          # auto_fix_timestamp(stockit_id, diffs, 'created_at', 'min') # DONE
        end
        log("AUTOFIX: updated #{@auto_fix_counter} data points")
        log("AUTOFIX: note @missing_orders_package_record_count is #{@missing_orders_package_record_count}") if @missing_orders_package_record_count > 0
        log("AUTOFIX: skipped #{@missing_order_or_package} orders_packages because order was not found in GoodCity.") if @missing_order_or_package > 0
      end

      AUTOFIX_COLUMNS = ["pieces", "grade", "length", "width", "height", "weight", "notes",
        "case_number", "inventory_number", "donor_condition_id"].freeze

      def auto_fix_single_columns(stockit_id, diffs)
        AUTOFIX_COLUMNS.each do |col|
          if diffs[col]
            stockit, goodcity = diffs[col]
            if goodcity.blank?
              Package.unscoped.where(stockit_id: stockit_id).update_all(col => stockit)
              log("Fixing Package stockit_id #{stockit_id}: #{col} set to #{stockit}")
              @auto_fix_counter += 1
            end
          end
        end
      end

      # Ignore GoodCity value. Override with Stockit value
      def auto_fix_box_id(stockit_id, diffs)
        if stockit_box_id = (diffs["box_id"] || {})[0]
          id = Box.find_by_stockit_id(stockit_box_id)&.id
          if id.present?
            Package.unscoped.where(stockit_id: stockit_id).update_all(box_id: id)
            log("Fixing Package stockit_id #{stockit_id}: box_id set to #{id}")
            @auto_fix_counter += 1
          end
        end
      end

      # Ignore GoodCity value. Override with Stockit value
      def auto_fix_pallet_id(stockit_id, diffs)
        if stockit_pallet_id = (diffs["pallet_id"] || {})[0]
          id = Pallet.find_by_stockit_id(stockit_pallet_id)&.id
          if id.present?
            Package.unscoped.where(stockit_id: stockit_id).update_all(pallet_id: id)
            log("Fixing Package stockit_id #{stockit_id}: pallet_id set to #{id}")
            @auto_fix_counter += 1
          end
        end
      end

      # If GoodCity orders_package.sent_on is blank, set available quantity to 0
      #   and ensure package is dispatched with correct date
      def auto_fix_dispatched(stockit_id, diffs)
        stockit_sent_on, goodcity_sent_on = (diffs["sent_on"] || [])
        if !stockit_sent_on.blank? # && goodcity_sent_on.blank?
          Package.unscoped.where(stockit_id: stockit_id).update_all(stockit_sent_on: stockit_sent_on, quantity: 0)
          op_query = OrdersPackage.joins(:package).where('packages.stockit_id = ?', stockit_id)
          if op_query.size == 0
            # INSERT: need to create OrdersPackage record
            stockit_record = @stockit_data[stockit_id] # access the entire record from Stockit
            stockit_order_code = stockit_record["code"]
            order_id = Order.where(code: stockit_order_code).first&.id
            package = Package.where(stockit_id: stockit_id).first
            if order_id.present? and package.present?
              attrs = { package_id: package.id, quantity: package.received_quantity, sent_on: stockit_sent_on, state: 'dispatched',
                updated_by_id: @updated_by_id, order_id: order_id, created_at: stockit_sent_on, updated_at: stockit_sent_on }
              sql_insert('orders_packages', attrs)
              @missing_orders_package_record_count += 1
              log("Fixing Package stockit_id #{stockit_id}: MISSING dispatched record created")
            else
              log("Fixing Package stockit_id #{stockit_id}: FAILED because order code #{stockit_order_code} or package stockit_id #{stockit_id} is missing")
              @missing_order_or_package += 1
            end
          else
            # UPDATE
            op_query.update_all(sent_on: stockit_sent_on, state: 'dispatched')
            log("Fixing Package stockit_id #{stockit_id}: dispatched record sent_on set to #{stockit_sent_on}")
          end
          @auto_fix_counter += 1
        end
      end

      # If stockit quantity differs from GoodCity and Stockit_quantity is not 0 then
      #   update received_quantity, orders_packages.quantity and packages_locations.quantity
      def auto_fix_quantity(stockit_id, diffs)
        stockit_quantity = (diffs["received_quantity"] || {})[0].to_i
        if stockit_quantity > 0 # {nil, "", 0}.to_i == 0
          Package.unscoped.where(stockit_id: stockit_id).update_all(received_quantity: stockit_quantity)
          OrdersPackage.joins(:package).
            where('packages.stockit_id = ?', stockit_id).
            update_all(quantity: stockit_quantity)
          PackagesLocation.joins(:package).
            where('packages.stockit_id = ?', stockit_id).
            update_all(quantity: stockit_quantity)
          log("Fixing Package stockit_id #{stockit_id}: received_quantity set to #{stockit_quantity}")
          @auto_fix_counter += 1
        end
      end

      # Location is "building+area"
      # Ignore GoodCity value. Override with Stockit value (unless dispatched in GoodCity)
      def auto_fix_locations(stockit_id, diffs)
        stockit_location, goodcity_location = (diffs["location"] || [])
        if stockit_location == 'Dispatched' or goodcity_location == 'Dispatched'
          # just delete the GoodCity PackageLocation record, regardless of it's entry
          PackagesLocation.unscoped.joins(:package).where('packages.stockit_id = ?', stockit_id).delete_all
          log("Deleting dispatched locations for #{stockit_id}")
        end
        if !stockit_location.blank?
          # Just move it to where Stockit says it is
          location_id = Location.unscoped.where("COALESCE(locations.building, '') || COALESCE(locations.area, '') = ?", stockit_location).first&.id
          if location_id
            package = Package.unscoped.where(stockit_id: stockit_id).first
            raise MissingGoodCityPackageError.new("Missing GoodCity package with stockit_id #{stockit_id}. This should never happen.") if package.nil?
            PackagesLocation.unscoped.joins(:package).where('packages.stockit_id = ?', stockit_id).delete_all
            sql_insert('packages_locations', location_id: location_id, package_id: package.id, 
              quantity: package.received_quantity, created_at: package.created_at, updated_at: package.created_at)
            log("Fixing location for #{stockit_id}")
            @auto_fix_counter += 1
          else
            log("Missing location: #{stockit_location} for stockit_id #{stockit_id}")
          end
        else
          log("Stockit location is blank for #{stockit_id}. Can't fix. diffs[location]: #{diffs['location']}")
        end
      end

      # When created_at, auto_fix_timestamp(stockit_id, diffs, 'created_at', 'min')
      # When updated_at, auto_fix_timestamp(stockit_id, diffs, 'updated_at', 'max')
      def auto_fix_timestamp(stockit_id, diffs, column, func)
        timestamp = (diffs[column] || []).map{|v| Time.parse(v)}.send(func)
        return if timestamp.blank?
        Package.unscoped.where(stockit_id: stockit_id).update_all(column => timestamp)
        log("Fixing Package #{column} for #{stockit_id}")
        @auto_fix_counter += 1
      end

      class MissingGoodCityPackageError < Exception
      end

    end

  end
end
