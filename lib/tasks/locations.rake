namespace :goodcity do

  # rails goodcity:remove_unused_locations
  desc 'Delete locations which does not have any associated data'
  task remove_unused_locations: :environment do
    Location.find_in_batches(batch_size: 100).each do |locations|
      locations.each do |location|
        if is_empty_location?(location)
          location.destroy
          puts "Deleted location: #{location.id} #{location.building}-#{location.area}"
        end
      end
    end
  end

  # rails goodcity:merge_locations
  desc 'Move data from one location to another and delete location'
  task merge_locations: :environment do
    source_location_id = ENV['SOURCE_LOCATION_ID']
    destination_location_id = ENV['DESTINATION_LOCATION_ID']

    source_location = Location.find_by(id: source_location_id)
    destination_location = Location.find_by(id: destination_location_id)

    if source_location.blank?
      puts "Source Location does not exist"
    elsif destination_location.blank?
      puts "Destination Location does not exist"
    else
      merge_location(source_location, destination_location)
      puts "Success!"

      if is_empty_location?(source_location)
        source_location.destroy
      end
    end
  end

  def merge_location(source_location, destination_location)
    ['Printer', 'Stocktake', 'PackagesInventory', 'PackageType', 'PackagesLocation', 'Package'].each do |klass|
      records = Object::const_get(klass).where(location_id: source_location.id)
      records.update_all(location_id: destination_location.id)
    end
  end

  def is_empty_location?(location)
    location.packages_locations.count.zero? &&
      location.package_types.count.zero? &&
      PackagesInventory.where(location_id: location.id).count.zero? &&
      Printer.where(location_id: location.id).count.zero? &&
      Stocktake.where(location_id: location.id).count.zero?
  end
end
