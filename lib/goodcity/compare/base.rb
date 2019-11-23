require 'csv'
require 'pg'

module Goodcity
  class Compare

    class Base

      def initialize
        @table = self.class.name.demodulize.underscore
        @differences = {}
        @counters = {}
        @missing_in_goodcity = []
        @missing_in_stockit = []
        @verbose = true
      end

      def run
        preload_data
        header_check
        calculate_differences
        populate_counters
        report
        write_differences_to_file
        write_missing_file("stockit")
        write_missing_file("goodcity")
      end

      def self.run
        new.run
      end

      private

      def preload_data
        @stockit_data ||= stockit_data
        @goodcity_data ||= goodcity_data
      end

      def calculate_differences
        @stockit_data.each do |stockit_id, stockit_row|
          goodcity_row = @goodcity_data[stockit_id]
          if goodcity_row.present?
            d = diff(stockit_row, goodcity_row)
            @differences[stockit_id] = d if d.any?
          else
            @missing_in_goodcity << stockit_id
          end
        end
        # Calculate the stockit_ids in GoodCity that are missing in Stockit
        @missing_in_stockit = @goodcity_data.keys - @stockit_data.keys
      end

      # How many of each column has a problem
      # counters = { location: 5122, code: 102 }
      def populate_counters
        @differences.each do |stockit_id, row|
          headers[1..-1].each do |col|
            @counters[col] = ((@counters[col] || 0) + 1) if row[col]&.any?
          end
        end
      end

      def report
        puts "Dataset size: Stockit #{@stockit_data.keys.size} | GoodCity #{@goodcity_data.keys.size}"
        puts "Differences found: #{@differences.size}"
        puts "Missing in GoodCity: #{@missing_in_goodcity.size}"
        puts "Missing in Stockit: #{@missing_in_stockit.size}"
        @counters.each{|header, count| puts "#{header}: #{count}"}
      end

      # Return the result of any differences between 2 hashes
      #   Treat nil and '' as equal
      #  a = {"width" => 1}; b = {"width" => 2}
      #  returns { "width" => [1, 2] }
      def diff(a,b)
        a.merge(b) do |k, v1, v2|
          (v1 || '') == (v2 || '') ? :equal : [v1, v2]
        end.reject { |_, v| v == :equal }
      end

      def bm(label = '', &block)
        result = nil
        time = Benchmark.measure(label) do
          result = yield
        end
        log(time.format("%n %t"))
        result
      end

      def log(msg)
        puts msg if @verbose
      end
      
      # confirm both datasets return the correct columns and in the correct order
      def header_check
        a = Set.new(@stockit_data.first.second.keys)
        b = Set.new(@goodcity_data.first.second.keys)
        missing_fields = a ^ b
        raise UnmatchedFieldsError.new("Stockit and GoodCity SQL fields don't match. Missing: #{missing_fields}") if missing_fields.any?
      end

      # ["stockit_id", "inventory_number", "quantity", "location", "code", "name", "first_name", "last_name"]
      def headers
        @stockit_data.first.second.keys
      end

      def write_differences_to_file
        file_name = File.join(Rails.root, 'tmp', "#{@table}_differences.csv")
        CSV.open(file_name, 'w') do |csv|
          csv << headers
          @differences.each do |stockit_id, diffs|
            row = [stockit_id]
            headers[1..-1].each do |col|
              row << (diffs[col] || []).join(" | ")
            end
            csv << row
          end
        end
        puts "Wrote #{file_name}"
      end

      # write_missing_file('stockit')
      # write_missing_file('goodcity')
      def write_missing_file(db_name)
        file_name = File.join(Rails.root, 'tmp', "#{@table}_missing_in_#{db_name}.csv")
        CSV.open(file_name, 'w') do |csv|
          csv << ['stockit_id']
          instance_variable_get("@missing_in_#{db_name}").each{|row| csv << [row]}
        end
        puts "Wrote #{file_name}"
      end

      # Transform data into a hash keyed by stockit_id
      # row1 and row2 are hashes
      # { "123245" => row1, "1232457" => row2 }
      def goodcity_data
        bm("Running GoodCity #{@table} SQL") do
          raw_data = ActiveRecord::Base.connection.execute(goodcity_sql)
          Hash[raw_data.map{|h| [h["stockit_id"], h] }]
        end
      end

      # executes 'stockit_sql' method and returns an enumerator where each row is a Hash
      # {"stockit_id"=>"341248", "created_at"=>"2019-11-16 03:41:01.477177+00", "updated_at"=>"2019-11-19 02:56:50.329426+00",
      #  "inventory_number"=>"12345", "received_quantity"=>"1", "location"=>"32Incoming", "code"=>"S1234",
      #  "name"=>"Org name", "first_name"=>"Contact first name", "last_name"=>"Contact last name"}
      def stockit_data
        bm("Running Stockit #{@table} SQL") do
          db_params = YAML.load_file("#{Rails.root}/config/database.yml")["stockit"]
          raise_missing_database_params_error if db_params.nil?
          conn = PG.connect(db_params.symbolize_keys!)
          raw_data = conn.exec(stockit_sql)
          Hash[raw_data.map{|h| [h["stockit_id"], h] }]
        end
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

    end

    class UnmatchedFieldsError < Exception
    end

    class MissingDatabaseParamsError < Exception
    end

  end
end
