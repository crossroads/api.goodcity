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
        # date_trunc('hour', items.created_at) as created_at,
        # date_trunc('hour', items.updated_at) as updated_at,
        # COALESCE(locations.building, '') || COALESCE(locations.area, '') as location, 
        # moved_by AS stockit_moved_by_id, designated_by AS stockit_designated_by_id, sent_by AS stockit_sent_by_id
        # moved_on AS stockit_moved_on, designated_on AS stockit_designated_on
        <<-SQL
        SELECT items.id as stockit_id, 
          inventory_number, quantity, case_number, grade, items.description AS notes,
          CASE condition WHEN 'N' THEN 1 WHEN 'U' THEN 3 WHEN 'M' THEN 2 WHEN 'B' THEN 4 END AS donor_condition_id,
          codes.code AS package_code,
          p.weight AS weight, p.width AS width, p.length AS length, p.height AS height, pieces,
          designations.code, organisations.name, contacts.first_name, contacts.last_name,
          pallet_id, items.box_id,
          to_char(items.sent_on, 'YYYY-MM-DD') AS sent_on
        FROM items
        LEFT JOIN (
          SELECT DISTINCT ON (item_id) * FROM packages
        ) AS p on items.id = p.item_id
        LEFT JOIN codes ON codes.id = items.code_id
        LEFT JOIN locations ON locations.id = items.location_id
        LEFT JOIN designations ON designations.id = items.designation_id
        LEFT JOIN organisations ON designations.organisation_id = organisations.id
        LEFT JOIN contacts ON designations.contact_id = contacts.id
        ORDER BY items.id DESC
        LIMIT 1000
        SQL
      end

      # this is really packages
      def goodcity_sql
        # to_char(date_trunc('hour', packages.created_at), 'YYYY-MM-DD HH24:MI:SS') as created_at,
        # to_char(date_trunc('hour', packages.updated_at), 'YYYY-MM-DD HH24:MI:SS') as updated_at,
        # locations.building || locations.area as location,
        # stockit_moved_by_id, stockit_designated_by_id, stockit_sent_by_id
        # stockit_moved_on, stockit_designated_on
        <<-SQL
        SELECT packages.stockit_id,
          inventory_number, received_quantity as quantity, case_number, grade, notes,
          donor_condition_id,
          package_types.code AS package_code,
          weight, width, length, height, pieces,
          orders.code, stockit_organisations.name, stockit_contacts.first_name, stockit_contacts.last_name,
          pallets.stockit_id AS pallet_id, boxes.stockit_id AS box_id,
          to_char(ops.sent_on, 'YYYY-MM-DD') AS sent_on
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
        ORDER BY packages.stockit_id DESC
        LIMIT 1000
        SQL
      end

      # handle case where X numbers are stored differently
      def diff(a,b)
        (a['inventory_number'] || '').gsub!(/^X/, '')
        (b['inventory_number'] || '').gsub!(/^X/, '')
        super
      end

    end

  end
end
