namespace :goodcity do

  # rake goodcity:update_package_type_description
  desc 'Update package type description'
  task update_package_type_description: :environment do

    package_types = YAML.load_file("#{Rails.root}/db/package_types.yml")
    package_types.each do |code, value|

      unless ["MDD","MDV","MFP"].include?(code)
        package_type = PackageType.find_by(code: code)
        package_type.update(
          name_en: value[:name_en],
          name_zh_tw: value[:name_zh_tw] )
      end
    end

  end

  # rake goodcity:update_package_type_default_location
  desc 'Update PackageType default location from Stockit'
  task update_package_type_default_location: :environment do

    codes_json = Stockit::CodeSync.index
    stockit_codes = JSON.parse(codes_json["codes"])

    if stockit_codes
      stockit_codes.each do |value|
        code = PackageType.find_by(stockit_id: value["id"])
        if code && value["location_id"].present?
          location_id = Location.find_by(stockit_id: value["location_id"]).try(:id)
          code.update_column(:location_id, location_id)
        end
      end
    end

  end
end
