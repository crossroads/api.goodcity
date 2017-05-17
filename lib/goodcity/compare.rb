require 'benchmark'
require 'ostruct'
require 'classes/diff'

module Goodcity
  class Compare

    attr_reader :diffs

    def initialize
      @diffs = {}
    end

    def compare
      compare_activities
      compare_boxes
      compare_codes
      compare_countries
      compare_locations
      compare_pallets
      compare_contacts
      compare_local_orders
      compare_organisations
      compare_items
      compare_orders
    end

    # Enumerator for diffs
    def each_diff(&block)
      @diffs.each_value{|diff| yield diff}
    end

    def summary
      number_of_diffs = @diffs.values.reject(&:identical?).size
      percent = (number_of_diffs.to_f / @diffs.values.size * 100).round(2)
      "#{number_of_diffs} differences / #{@diffs.values.size} objects (#{percent}%)"
    end

    def in_words
      sorted_diffs.reject(&:identical?).map(&:in_words)
    end

    def sorted_diffs
      @diffs.values.sort_by{|d| [d.klass_name, d.id]}
    end

    def compare_activities
      stockit_activities = stockit_json(Stockit::ActivitySync, "activities")
      compare_objects(StockitActivity, stockit_activities, [:name])
    end

    def compare_boxes
      # can't compare :pallet_id to stockit_pallet_id
      stockit_boxes = stockit_json(Stockit::BoxSync, "boxes")
      compare_objects(Box, stockit_boxes, [:description, :box_number, :comments])
    end

    def compare_codes
      # missing :description_en, :description_zht, :location_id (stockit_location_id and location_id are different)
      stockit_codes = stockit_json(Stockit::CodeSync, "codes")
      compare_objects(PackageType, stockit_codes, [:code])
    end

    def compare_countries
      #missing name_zh_tw
      stockit_countries = stockit_json(Stockit::CountrySync, "countries")
      compare_objects(Country, stockit_countries, [:name_en])
    end

    def compare_locations
      stockit_locations = stockit_json(Stockit::LocationSync, "locations")
      compare_objects(Location, stockit_locations, [:area, :building])
    end

    def compare_pallets
      stockit_pallets = stockit_json(Stockit::PalletSync, "pallets")
      compare_objects(Pallet, stockit_pallets, [:pallet_number, :description, :comments])
    end

    def compare_contacts
      stockit_contacts = stockit_json(Stockit::ContactSync, "contacts")
      compare_objects(StockitContact, stockit_contacts, [:first_name, :last_name, :phone_number, :mobile_phone_number])
    end

    # TODO pagination
    def compare_local_orders
      stockit_local_orders = stockit_json(Stockit::LocalOrderSync, "local_orders")
      compare_objects(StockitLocalOrder, stockit_local_orders, [:purpose_of_goods, :hkid_number, :reference_number, :client_name])
    end

    # TODO pagination
    def compare_organisations
      stockit_organisations = stockit_json(Stockit::OrganisationSync, "organisations")
      compare_objects(StockitOrganisation, stockit_organisations, [:name])
    end

    def compare_items
      # Missing mappings
      # Stockit : GoodCity
      # : deleted_at
      # code_id: :package_type_id
      # donor_condition_id : condition
      # designation_code :
      # designation_id: order_id
      # : designation_name
      # sent_on : stockit_sent_on
      # : stockit_sent_by_id
      # : stockit_moved_on
      # : stockit_moved_by_id
      # : stockit_designated_on
      # : stockit_designated_by_id
      # TODO
      # paginated but need to memoize the gc objects in compare_objects function
      #   as these keep being rebuilt
      # also use 'select' statements so not building AR objects
      # rethink structure of comparision - two loops to ensure missing included
      #   better to use ids for missing items
      paginated_json(Stockit::ItemSync, "items", 0, 1000) do |stockit_items|
        compare_objects(Package, stockit_items, [:box_id, :case_number, :code_id, :condition, :description, :grade, :height, :inventory_number, :length, :location_id, :pallet_id, :quantity, :sent_on, :width])
      end
    end

    def compare_orders
      # TODO: pagination
      # Not in Stockit JSON
      # :processed_by_id, :purpose_description, :stockit_organisation_id
      # TODO: to be mapped
      # Stockit : GoodCity
      # contact_id : stockit_contact_id
      # activity_id : stockit_activity_id
      # organisation_id : stockit_organisation -> stockit_id
      # detail_id : detail.stockit_id
      stockit_designations = stockit_json(Stockit::DesignationSync, "designations")
      compare_objects(Order, stockit_designations, [:code, :country_id, :description, :detail_type, :status])
    end

    private

    # compare_objects(StockitActivity, stockit_activities, [:name])
    # TODO change to loop just once and use ids (Set) to find missing items
    def compare_objects(goodcity_klass, stockit_objects, attributes_to_compare=[])
      attributes_to_compare |= [:id, :stockit_id] # ensure these are included if not already
      
      # Preloading GC objects
      goodcity_objects_hash = {} # keyed by stockit_id
      goodcity_objects = [] # for iterating later (includes those with empty or duplicate stockit_ids)
      bm('Preloading GC objects') do
        goodcity_klass.find_each do |obj|
          goodcity_objects_hash[obj.stockit_id] = obj
          goodcity_objects << obj
        end
      end

      # Iterate over Stockit JSON
      bm('stockit_objects') do
        stockit_objects.each_value do |stockit_obj|
          goodcity_obj = goodcity_objects_hash[stockit_obj["id"]]
          goodcity_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, goodcity_obj.try(a)]}.flatten])
          stockit_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, stockit_obj[a.to_s]]}.flatten])
          diff = Diff.new("#{goodcity_klass}", goodcity_struct, stockit_struct, attributes_to_compare).compare
          @diffs.merge!(diff.key => diff)
        end
      end
      # Iterate over GoodCity class
      bm('goodcity_objects') do
        goodcity_objects.each do |goodcity_obj|
          goodcity_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, goodcity_obj.try(a)]}.flatten])
          stockit_obj = stockit_objects[goodcity_obj.stockit_id] || {}
          stockit_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, stockit_obj[a.to_s]]}.flatten])
          diff = Diff.new("#{goodcity_klass}", goodcity_struct, stockit_struct, attributes_to_compare).compare
          @diffs.merge!(diff.key => diff)
        end
      end
    end

    def stockit_json(klass, root)
      bm('stockit_json') do
        json_data = klass.index
        data = JSON.parse(json_data[root]) || []
        data.inject({}){|h,k| h[k['id']]=k; h}
      end
    end

    # For API endpoints that are paginated, iterate and yield the block each time
    def paginated_json(klass, root, offset, per_page, &block)
      loop do
        json = klass.index(nil, offset, per_page)
        json_objects = JSON.parse(json[root])
        if json_objects.present?
          yield json_objects.inject({}){|h,k| h[k['id']]=k; h}
        else
          break
        end
        offset = offset + per_page
      end
    end

    def bm(label = '', &block)
      result = nil
      time = Benchmark.measure(label) do
        result = yield
      end
      (puts time.format("%n %t")) if %w(development staging).include?(Rails.env)
      result
    end

  end
end
