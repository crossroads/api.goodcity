namespace :stockit do

  desc <<-eos
    Sync data from Stockit.
    This task syncs GoodCity up with Stockit data.
    It won't delete data but it will overwrite GoodCity
    with Stockit's data.
  eos
  task sync: :environment do
    puts "Activities"
    Rake::Task["stockit:add_stockit_activities"].execute
    puts "Countries"
    Rake::Task["stockit:add_stockit_countries"].execute
    puts "Locations"
    Rake::Task["stockit:add_stockit_locations"].execute
    puts "Codes"
    Rake::Task["stockit:add_stockit_codes"].execute
    puts "Pallets and boxes"
    Rake::Task["stockit:add_stockit_pallets_boxes"].execute
    puts "Organisations"
    Rake::Task["stockit:add_stockit_organisations"].execute
    puts "Contacts"
    Rake::Task["stockit:add_stockit_contacts"].execute
    puts "Local orders"
    Rake::Task["stockit:add_stockit_local_orders"].execute
    puts "Designations"
    Rake::Task["stockit:add_designations"].execute
    puts "Items"
    Rake::Task["stockit:add_stockit_items"].execute
    puts "PackageTypes"
    Rake::Task["goodcity:update_package_type_default_location"].execute
    puts "OrdersPackages"
    Rake::Task["goodcity:update_orders_packages_data"].execute
  end
end
