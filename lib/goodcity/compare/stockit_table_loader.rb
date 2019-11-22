# Add the following to database.yml
# Note the format is different to a usual Rails db config
#
# stockit:
#   host: <DB>.postgres.database.azure.com
#   dbname: 
#   user: 
#   password: 
#   sslmode: require

module Goodcity
  class Compare

    class StockitTableLoader

      class << self

        # executes 'sql' method and returns an enumerator where each row is a Hash
        def load(table)
          db_params = YAML.load_file("#{Rails.root}/config/database.yml")["stockit"]
          raise_missing_database_params_error if db_params.nil?
          conn = PG.connect(db_params.symbolize_keys!)
          sql = send("#{table}_sql")
          conn.exec(sql)
        end

        def items_sql
          # date_trunc('hour', items.created_at) as created_at,
          # date_trunc('hour', items.updated_at) as updated_at,
          # COALESCE(locations.building, '') || COALESCE(locations.area, '') as location, 
          <<-SQL
          SELECT items.id as stockit_id, 
            inventory_number, quantity, case_number, grade,
            CASE condition WHEN 'N' THEN 1 WHEN 'U' THEN 3 WHEN 'M' THEN 2 WHEN 'B' THEN 4 END AS donor_condition_id,
            p.weight AS weight, p.width AS width, p.length AS length, p.height AS height, pieces,
            designations.code, organisations.name, contacts.first_name, contacts.last_name
          FROM items
          JOIN (SELECT DISTINCT ON (item_id) * FROM packages ORDER BY item_id) AS p on items.id = p.item_id
          JOIN locations ON locations.id = items.location_id
          JOIN designations ON designations.id = items.designation_id
          JOIN organisations ON designations.organisation_id = organisations.id
          JOIN contacts ON designations.contact_id = contacts.id
          ORDER BY items.id DESC
          LIMIT 1000
          SQL
        end

        def raise_missing_database_params_error
          raise MissingDatabaseParamsError.new(
            <<-MSG
            Please provide the following 'stockit' database connection params in database.yml:
              stockit:
                host:
                dbname: 
                user: 
                password: 
                sslmode: require
            MSG
          )
        end

        class MissingDatabaseParamsError < Exception
        end

      end # self << class

    end
  end
end