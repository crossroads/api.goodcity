require 'ostruct'
require 'classes/diff'

module Goodcity
  class Compare

    def initialize
    end

    def compare
      compare_activities
      compare_boxes
      compare_codes
      compare_countries
      compare_locations
      compare_pallets
      # TODO
      # StockitContact
      # StockitLocalOrder
      # StockitOrganisation
      # Designation / Order
      # Item
    end

    def compare_activities
      compare_objects(StockitActivity, stockit_activities, [:id, :name])
    end

    def compare_boxes
      compare_objects(Box, stockit_boxes, [:pallet_id, :description, :box_number, :comments])
    end

    def compare_codes
      # missing :description_en, :description_zht
      compare_objects(PackageType, stockit_codes, [:location_id, :code])
    end

    def compare_countries
      #missing name_zh_tw
      compare_objects(Country, stockit_countries, [:name_en])
    end

    def compare_locations
      compare_objects(Location, stockit_locations, [:area, :building])
    end

    def compare_pallets
      compare_objects(Pallet, stockit_pallets, [:pallet_number, :description, :comments])
    end

    private

    # compare_objects(StockitActivity, stockit_activities, [:name])
    def compare_objects(goodcity_klass, stockit_objects, attributes_to_compare=[])
      attributes_to_compare |= [:id, :stockit_id] # ensure these are included if not already
      diffs = []
      # Iterate over Stockit JSON
      stockit_objects.each do |stockit_obj|
        goodcity_obj = goodcity_klass.find_by(stockit_id: stockit_obj["id"])
        goodcity_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, goodcity_obj.try(a)]}.flatten])
        stockit_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, stockit_obj[a.to_s]]}.flatten])
        diffs << Diff.new("#{goodcity_klass}", goodcity_struct, stockit_struct, attributes_to_compare).compare
      end
      # Iterate over GoodCity class
      goodcity_klass.all.each do |goodcity_obj|
        goodcity_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, goodcity_obj.try(a)]}.flatten])
        stockit_obj = stockit_objects.select{|a| a["id"] == goodcity_obj.stockit_id}.first || {}
        stockit_struct = OpenStruct.new(Hash[*attributes_to_compare.map{|a| [a, stockit_obj[a.to_s]]}.flatten])
        diffs << Diff.new("#{goodcity_klass}", goodcity_struct, stockit_struct, attributes_to_compare).compare
      end
      puts diffs.reject(&:identical?).sort.map(&:in_words).join("\n")
    end

    def stockit_activities
      @stockit_activities ||= begin
        json_data = Stockit::ActivitySync.index
        JSON.parse(json_data["activities"]) || []
      end
    end

    def stockit_boxes
      @stockit_boxes ||= begin
        json_data = Stockit::BoxSync.index
        JSON.parse(json_data["boxes"]) || []
      end
    end

    def stockit_codes
      @stockit_codes ||= begin
        json_data = Stockit::CodeSync.index
        JSON.parse(json_data["codes"]) || []
      end
    end
    
    def stockit_countries
      @stockit_countries ||= begin
        json_data = Stockit::CountrySync.index
        JSON.parse(json_data["countries"]) || []
      end
    end

    def stockit_locations
      @stockit_locations ||= begin
        json_data = Stockit::LocationSync.index
        JSON.parse(json_data["locations"]) || []
      end
    end

    def stockit_pallets
      @stockit_pallets ||= begin
        json_data = Stockit::PalletSync.index
        JSON.parse(json_data["pallets"]) || []
      end
    end

  end
end
