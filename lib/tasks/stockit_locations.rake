namespace :stockit do

  desc 'Load location details from Stockit'
  task add_stockit_locations: :environment do
    locations_json = Stockit::LocationSync.index
    stockit_locations = JSON.parse(locations_json["locations"]) || []
    stockit_locations.each do |value|
      location = Location.where(stockit_id: value["id"]).first_or_initialize
      location.building = value["building"]
      location.area = value["area"]
      location.save
    end
  end

end
