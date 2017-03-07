namespace :stockit do

  desc 'Load code details from Stockit'
  task add_stockit_codes: :environment do
    
    codes_json = Stockit::CodeSync.index
    stockit_codes = JSON.parse(codes_json["codes"])

    if stockit_codes

      stockit_codes.each do |value|
        is_new_code = false

        code = PackageType.where(code: value["code"], stockit_id: nil).first_or_initialize
        code.name_en = value["description_en"]
        code.name_zh_tw = value["description_zht"]
        code.stockit_id = value["id"]
        is_new_code = code.new_record?
        code.save

        if is_new_code && code.default_child_package_types.count.zero?
          SubpackageType.create(
            package_type: code,
            child_package_type: code,
            is_default: true)
        end
      end
    end

    new_gc_codes = PackageType.where("stockit_id IS NULL")
    new_gc_codes.each do |code|
      response = Stockit::CodeSync.create(code)
      code.update_column(:stockit_id, response["code_id"]) if response["code_id"].present?
    end

    package_type = PackageType.find_by(code: "VXX")
    if package_type
      package_type.update_column(:name_en, "Other types of computer equipment")
    end

  end
end
