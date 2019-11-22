module Goodcity
  class Compare
    class GoodcityTableLoader

      class << self

        def load(table)
          sql = send("#{table}_sql")
          ActiveRecord::Base.connection.execute(sql)
        end

        # this is really packages
        def items_sql
          # to_char(date_trunc('hour', packages.created_at), 'YYYY-MM-DD HH24:MI:SS') as created_at,
          # to_char(date_trunc('hour', packages.updated_at), 'YYYY-MM-DD HH24:MI:SS') as updated_at,
          # locations.building || locations.area as location,
          <<-SQL
          SELECT packages.stockit_id,
            inventory_number, received_quantity as quantity, case_number, grade,
            donor_condition_id,
            weight, width, length, height, pieces,
            orders.code, stockit_organisations.name, stockit_contacts.first_name, stockit_contacts.last_name
          FROM packages
          JOIN donor_conditions ON donor_conditions.id = packages.donor_condition_id
          JOIN packages_locations on packages_locations.package_id = packages.id
          JOIN locations ON locations.id = packages_locations.location_id
          JOIN orders_packages ON orders_packages.package_id = packages.id
          JOIN orders ON orders.id = orders_packages.order_id
          JOIN stockit_organisations ON stockit_organisations.id = orders.stockit_organisation_id
          JOIN stockit_contacts ON stockit_contacts.id = orders.stockit_contact_id
          ORDER BY packages.stockit_id DESC
          LIMIT 1000
          SQL
        end

      end # class << self

    end
  end
end