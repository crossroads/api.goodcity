namespace :goodcity do

  # rake goodcity:add_stockit_locations
  desc 'Load location details from stockit'
  task add_stockit_locations: :environment do
    Location.delete_all

    locations = YAML.load_file("#{Rails.root}/db/locations.yml")
    locations.each do |value|
      FactoryGirl.create(:location,
        building: value["building"],
        area: value["area"],
        stockit_id: nil )
    end

    locations_json = Stockit::Location.index
    stockit_locations = JSON.parse(locations_json["locations"])

    if stockit_locations
      stockit_locations.each do |value|
        location = Location.where(
          building: value["building"],
          area: value["area"]
        ).first_or_create
        location.update_attribute(:stockit_id, value["id"])
      end
    end
  end
end
