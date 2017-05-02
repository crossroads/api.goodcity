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
      sync_attributes = [:id, :name]
      self.class.const_set(:AttributesStruct, Struct.new(*sync_attributes))
      diffs = []
      # Iterate over Stockit JSON
      activities_json = Stockit::ActivitySync.index
      activities = JSON.parse(activities_json["activities"]) || []
      activities.each do |value|
        activity = StockitActivity.find_by(stockit_id: value["id"])
        goodcity_struct = AttributesStruct.new(*sync_attributes.map{|a| activity.try(a)})
        stockit_struct = AttributesStruct.new(*sync_attributes.map{|a| value[a.to_s]})
        diffs << Diff.new("StockitActivity", goodcity_struct, stockit_struct, sync_attributes).compare
      end
      # Iterate over GoodCity StockitActivity
      StockitActivity.all.each do |activity|
        goodcity_struct = AttributesStruct.new(*sync_attributes.map{|a| activity.try(a)})
        stockit_activity = activities.select{|a| a["id"] == activity.stockit_id}.first || {}
        stockit_struct = AttributesStruct.new(*sync_attributes.map{|a| stockit_activity[a.to_s]})
        diffs << Diff.new("StockitActivity", goodcity_struct, stockit_struct, sync_attributes).compare
      end
      puts diffs.reject(&:identical?).sort.map(&:in_words).join("\n")
    end

  end
end