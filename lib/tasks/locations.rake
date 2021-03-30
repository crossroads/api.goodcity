namespace :goodcity do
  # rails goodcity:remove_unused_locations
  desc 'Delete locations which does not have any associated data'
  task remove_unused_locations: :environment do
    Location.find_in_batches(batch_size: 100).each do |locations|
      locations.each do |location|
        if ManageLocation.new(location.id).empty_location?
          location.destroy
          puts "Deleted location: #{location.id} #{location.building}-#{location.area}"
        end
      end
    end
  end

  # rails goodcity:merge_locations
  desc 'Move data from one location to another and delete location'
  task merge_locations: :environment do
    source_location = Location.find_by(id: ENV["SOURCE_LOCATION_ID"])
    destination_location = Location.find_by(id: ENV["DESTINATION_LOCATION_ID"])

    if source_location.blank?
      puts "Source Location does not exist"
    elsif destination_location.blank?
      puts "Destination Location does not exist"
    else
      ManageLocation.merge_location(source_location, destination_location)
      puts "Success!"

      if ManageLocation.new(source_location.id).empty_location?
        source_location.destroy
      end
    end
  end
end
