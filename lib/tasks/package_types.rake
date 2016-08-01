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
end
