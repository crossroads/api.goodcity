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
    stockit_codes = JSON.parse(codes_json["codes"]) || {}
    stockit_codes.each do |value|
      code = PackageType.find_by(stockit_id: value["id"])
      if code && value["location_id"].present?
        location_id = Location.find_by(stockit_id: value["location_id"]).try(:id)
        code.update_column(:location_id, location_id)
      end
    end
  end

  # rake goodcity:update_allow_stock_to_stockit_codes_status
  desc 'Update PackageType `allow_stock` according to `Codes.status` from Stockit'
  task update_allow_stock_to_stockit_codes_status: :environment do
    STATUS_AND_ALLOW_STOCK_MAPPING = {
      "Active" => true,
      "Inactive" => false
    }.freeze
    log = Goodcity::RakeLogger.new("update_allow_stock_to_stockit_codes_status")
    updated_record_count = 0
    failed_record_count = 0
    failed_package_type_ids = []
    codes_json = Stockit::CodeSync.index
    stockit_codes = JSON.parse(codes_json["codes"]) || {}
    stockit_codes.each do |code|
      if active?(code["status"]) and package_type = get_package_type(code["id"])
        if package_type.update_column(:allow_stock, true)
          updated_record_count += 1
        else
          failed_record_count += 1
          failed_package_type_ids << package_type.id
        end
      end
    end
    log.info("TOTAL Record = #{stockit_codes.count}")
    log.info("TOTAL UPDATED RECORD = #{updated_record_count}")
    log.info("TOTAL FAILED UPDATES = #{failed_record_count}")
    log.info("LIST OF FAILED RECORDS = #{failed_package_type_ids}")
  end

  def get_package_type(id)
    PackageType.find_by(stockit_id: id)
  end

  def active?(status)
    STATUS_AND_ALLOW_STOCK_MAPPING[status]
  end

end
