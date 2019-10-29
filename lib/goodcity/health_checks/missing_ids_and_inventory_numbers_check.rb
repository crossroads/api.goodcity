# 
# Before executing this script, run the following SQL queries and save them.
#
# GoodCity
#   SELECT stockit_id, inventory_number FROM packages;
#   save in tmp/goodcity_package_stockit_ids.csv

# Stockit
#   SELECT id, inventory_number FROM items;
#   save in tmp/stockit_items_ids.csv

# Rails Console
#   > require 'goodcity/health_checks/missing_ids_and_inventory_numbers_check'
#   > chk = Goodcity::HealthChecks::MissingIdsAndInventoryNumbersCheck.new
#   > chk.run

# Decision: ignore duplicate stockit_id entries, code below won't distinguish

require 'csv'
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class MissingIdsAndInventoryNumbersCheck < Base
      desc "Dispatched packages should contain an order_id reference."

      GC_FILE_NAME = "goodcity_package_stockit_ids.csv"
      STOCKIT_FILE_NAME = "stockit_item_ids.csv"

      def initialize
        reset
      end

      def reset
        @correctly_syncd_stockit_ids = []      # Count of stockit_id and inventory_numbers that match correctly in both GoodCity and Stockit
        @mismatched_inventory_numbers = []     # Inventory numbers from GoodCity that don't match their counterpart in Stockit
        @mismatched_stockit_ids = []           # GoodCity inventory_numbers that have a different stockit_id in Stockit
        @missing_id_and_inventory_numbers = [] # stockit_id and inventory_numbers from GoodCity that don't have ANY match in Stockit.
      end

      def run
        reset
        fail! unless (check_file_exists?(GC_FILE_NAME) and check_file_exists?(STOCKIT_FILE_NAME))
        process
        report
        pass!
      end

      private

      # In Stockit, look to see if the GoodCity stockit_ids and inventory_numbers exist
      def process
        goodcity_package_stockit_ids = load_csv_file(GC_FILE_NAME)
        stockit_item_ids = load_csv_file(STOCKIT_FILE_NAME)
        inverted_stockit_item_ids = stockit_item_ids.invert

        goodcity_package_stockit_ids.each do |stockit_id, inventory_number|
          if stockit_item_ids.has_key?(stockit_id)
            # GC stockit_id does exist in Stockit, confirm inventory number is correct
            if stockit_item_ids[stockit_id] == inventory_number
              @correctly_syncd_stockit_ids << [stockit_id, inventory_number]
            else
              # stockit_id matches but inventory number doesn't, could be a duplicate but we don't know
              @mismatched_inventory_numbers << [stockit_id, inventory_number, stockit_item_ids[stockit_id]]
            end
          else
            # GC stockit_id doesn't exist in Stockit, do a global look for inventory number
            if inverted_stockit_item_ids.has_key?(inventory_number)
              # Found GoodCity inventory_number in Stockit but it has a different stockit_id
              @mismatched_stockit_ids << [inventory_number, stockit_id, inverted_stockit_item_ids[inventory_number]]
            else
              # Neither GoodCity stockit_id or inventory_number exist anywhere in Stockit
              @missing_id_and_inventory_numbers << [stockit_id, inventory_number]
            end
          end
        end
      
        write_csv("correctly_syncd_stockit_ids.csv", ["stockit_id", "inventory_number"], @correctly_syncd_stockit_ids)
        write_csv("mismatched_inventory_numbers.csv", ["stockit_id", "gc_inventory_number", "stockit_inventory_number"], @mismatched_inventory_numbers)
        write_csv("mismatched_stockit_ids.csv", ["inventory_number", "gc_stockit_id", "stockit_item_id"], @mismatched_stockit_ids)
        write_csv("missing_id_and_inventory_numbers.csv", ["stockit_id", "inventory_number"], @missing_id_and_inventory_numbers)
      end

      def report
        puts "#{@correctly_syncd_stockit_ids.size} correct entries ( tmp/correctly_sync_stockit_ids.csv )"
        puts "#{@mismatched_inventory_numbers.size} matching stockit_ids but differing inventory_numbers ( tmp/mismatched_inventory_numbers.csv )"
        puts "#{@mismatched_stockit_ids.size} matching inventory_numbers but differing stockit_ids ( tmp/mismatched_stockit_ids.csv )"
        puts "#{@missing_id_and_inventory_numbers.size} GoodCity stockit_ids/inventory_numbers that do NOT exist at all in Stockit ( tmp/missing_id_and_inventory_numbers.csv )"
      end

      def check_file_exists?(file_name)
        file_path = File.join(Rails.application.root, "tmp", file_name)
        unless File.exist?(file_path)
          puts "Please create #{file_path} with the correct SQL output."
          puts "  For GoodCity use: 'SELECT stockit_id, inventory_number FROM packages;'"
          puts "  For Stockit use: 'SELECT id, inventory_number FROM items;'"
          puts "Ensure line 1 includes a header row."
        end
      end

      def load_csv_file(file_name)
        rows = {} # { stockit_id => inventory_number }
        file_path = File.join(Rails.application.root, "tmp", file_name)
        CSV.foreach(file_path, headers: false) do |row|
          rows[row[0]] = row[1]
        end
        rows
      end

      # file_name: name of file to place in Rails_root/tmp/ folder
      # header: array of header columns [ col1, col2 ]
      # contents: 2D array of data [ [row1col1, row1col2], [row2col1, row2col2] ]
      def write_csv(file_name, header, contents)
        file_path = File.join(Rails.application.root, "tmp", file_name)
        CSV.open(file_path, "wb") do |csv|
          csv << header
          contents.each do |row|
            csv << row
          end
        end
      end
    
    end
  end
end