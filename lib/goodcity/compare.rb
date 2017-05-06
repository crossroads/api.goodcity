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

    def in_words
      @diffs.values.reject(&:identical?).sort.map(&:in_words).join("\n")
    end

    def compare_activities
      stockit_activities = stockit_json(Stockit::ActivitySync, "activities")
      compare_objects(StockitActivity, stockit_activities, [:name])
    end

    def compare_boxes
      stockit_boxes = stockit_json(Stockit::BoxSync, "boxes")
      compare_objects(Box, stockit_boxes, [:pallet_id, :description, :box_number, :comments])
    end

    def compare_codes
      # missing :description_en, :description_zht
      stockit_codes = stockit_json(Stockit::CodeSync, "codes")
      compare_objects(PackageType, stockit_codes, [:location_id, :code])
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

    def compare_local_orders
      stockit_local_orders = stockit_json(Stockit::LocalOrderSync, "local_orders")
      compare_objects(StockitLocalOrder, stockit_local_orders, [:purpose_of_goods, :hkid_number, :reference_number, :client_name])
    end

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
      paginated_json(Stockit::ItemSync, "items", 0, 1000) do |stockit_items|
        compare_objects(Package, stockit_items, [:box_id, :case_number, :code_id, :condition, :description, :grade, :height, :inventory_number, :length, :location_id, :pallet_id, :quantity, :sent_on, :width])
      end
    end

    def compare_orders
      # Not in Stockit JSON
      # :processed_by_id, :purpose_description, :stockit_organisation_id
      # TODO: to be mapped
      # Stockit : GoodCity
      # contact_id : stockit_contact_id
      # activity_id : stockit_activity_id
      stockit_designations = stockit_json(Stockit::DesignationSync, "designations")
      compare_objects(Order, stockit_designations, [:code, :country_id, :description, :detail_id, :detail_type, :organisation_id, :status])
    end

    private

    # compare_objects(StockitActivity, stockit_activities, [:name])
    def compare_objects(goodcity_klass, stockit_objects, attributes_to_compare=[])
      attributes_to_compare |= [:id, :stockit_id] # ensure these are included if not already
      # Iterate over Stockit JSON
      stockit_objects.each do |stockit_obj|
        goodcity_obj = goodcity_klass.find_by(stockit_id: stockit_obj["id"])
        goodcity_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, goodcity_obj.try(a)]}.flatten])
        stockit_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, stockit_obj[a.to_s]]}.flatten])
        diff = Diff.new("#{goodcity_klass}", goodcity_struct, stockit_struct, attributes_to_compare).compare
        @diffs.merge!(diff.key => diff)
      end
      # Iterate over GoodCity class
      goodcity_klass.all.each do |goodcity_obj|
        goodcity_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, goodcity_obj.try(a)]}.flatten])
        stockit_obj = stockit_objects.select{|a| a["id"] == goodcity_obj.stockit_id}.first || {}
        stockit_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, stockit_obj[a.to_s]]}.flatten])
        diff = Diff.new("#{goodcity_klass}", goodcity_struct, stockit_struct, attributes_to_compare).compare
        @diffs.merge!(diff.key => diff)
      end
    end

    def stockit_json(klass, root)
      json_data = klass.index
      JSON.parse(json_data[root]) || []
    end

    # For API endpoints that are paginated, iterate and yield the block each time
    def paginated_json(klass, root, offset, per_page, &block)
      loop do
        json = klass.index(nil, offset, per_page)
        json_objects = JSON.parse(json[root])
        if json_objects.present?
          yield json_objects
        else
          break
        end
        offset = offset + per_page
      end
    end

  end
end
