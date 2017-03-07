namespace :stockit do

  desc 'Load location details from Stockit'
  task add_stockit_locations: :environment do

    locations_json = Stockit::LocationSync.index
    stockit_locations = JSON.parse(locations_json["locations"])

    if stockit_locations.present?
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
