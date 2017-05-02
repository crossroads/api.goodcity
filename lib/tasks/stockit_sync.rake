namespace :stockit do

  desc <<-eos
    Sync data from Stockit.
    This task syncs GoodCity up with Stockit data.
    It won't delete data but it will overwrite GoodCity
    with Stockit's data. Once done, it will generate
    OrdersPackages and sync them to Stockit.
  eos
  task sync: :environment do
    puts "Getting Stockit Activities"
    Rake::Task["stockit:add_stockit_activities"].execute
    puts "Getting Stockit Countries"
    Rake::Task["stockit:add_stockit_countries"].execute
    puts "Getting Stockit Locations"
    Rake::Task["stockit:add_stockit_locations"].execute
    puts "Getting Stockit Codes"
    Rake::Task["stockit:add_stockit_codes"].execute
    puts "Update PackageType default locations"
    Rake::Task["goodcity:update_package_type_default_location"].execute
    
    puts "Getting Stockit Pallets and boxes"
    Rake::Task["stockit:add_stockit_pallets_boxes"].execute
    puts "Getting Stockit Organisations"
    Rake::Task["stockit:add_stockit_organisations"].execute
    puts "Getting Stockit Contacts"
    Rake::Task["stockit:add_stockit_contacts"].execute
    puts "Getting Stockit Local orders"
    Rake::Task["stockit:add_stockit_local_orders"].execute
    puts "Getting Stockit Designations"
    Rake::Task["stockit:add_designations"].execute
    puts "Getting Stockit Items (takes a long time)"
    Rake::Task["stockit:add_stockit_items"].execute
    puts "Generate OrdersPackages and sync them to Stockit"
    Rake::Task["goodcity:update_orders_packages_data"].execute
  end

  desc "Are GoodCity and Stockit activities in sync?"
  task compare_activities: :environment do
    sync_attributes = [:id, :name]
    AttributesStruct = Struct.new(*sync_attributes)
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
