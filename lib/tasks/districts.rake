namespace :goodcity do

  # rake goodcity:update_lat_long_for_districts
  desc 'Update latitude and longitude values for districts'
  task update_lat_long_for_districts: :environment do
    districts = YAML.load_file("#{Rails.root}/db/districts.yml")
    districts.each do |name_en, value|
      district = District.unscoped.where(name_en: name_en).first_or_create
      district.update_attributes(
        latitude:  value[:latitude],
        longitude: value[:longitude]
      )
    end
  end

  # Add "Geocoder" gem in your gemfile before running this rake task
  # rake goodcity:geocode_districts
  desc "Find latitude and longitude for district using Geocoder service"
  task geocode_districts: :environment do
    Geocoder.configure(:timeout => 10)
    District.find_in_batches(batch_size: 50).each do |districts|
      districts.each do |district|
        if district.latitude.blank?
          address = "#{district.name}, #{district.territory.name}"
          results = Geocoder.search(address)

          if(results.first)
            location = results.first.data["geometry"]["location"]

            district.update_attributes(
              latitude:  location["lat"],
              longitude: location["lng"]
            )

            puts "Done #{district.id}"
            sleep(0.5)
          end
        end
      end
    end
  end

  # rake goodcity:update_districts_yml
  desc "Update values of latitude and longitude in districts.yml file"
  task update_districts_yml: :environment do
    districts_data = YAML.load_file("#{Rails.root}/db/districts.yml")

    District.find_in_batches(batch_size: 50).each do |districts|
      districts.each do |district|
        districts_data[district.name][:latitude] = district.latitude
        districts_data[district.name][:longitude] = district.longitude
      end
    end

    File.open("#{Rails.root}/db/districts.yml",'w') do |h|
       h.write districts_data.to_yaml
    end
  end
end

