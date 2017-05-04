require 'ostruct'
require 'classes/diff'

module Goodcity
  class Compare

    def initialize
    end

    def compare
      compare_activities
    end

    def self.compare
      self.new.compare
    end

    private

    def compare_activities
      compare_objects(StockitActivity, stockit_activities, [:id, :name])
    end

    # compare_objects(StockitActivity, stockit_activities, [:id, :name])
    def compare_objects(goodcity_klass, stockit_objects, attributes_to_compare = [:id, :name])
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
        stockit_objects = JSON.parse(json_data["activities"]) || []
      end
    end

  end
end
