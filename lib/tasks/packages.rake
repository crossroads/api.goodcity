namespace :goodcity do

  # rake goodcity:update_packages
  desc 'update_packages'
  task update_packages: :environment do

    package_types = YAML.load_file("#{Rails.root}/db/package_types.yml")
    package_types.each do |code, value|
      PackageType.create(
        code: code,
        name_en: value[:name_en],
        name_zh_tw: value[:name_zh_tw],
        other_terms_en: value[:other_terms_en],
        other_terms_zh_tw: value[:other_terms_zh_tw] )
    end

    package_types.each do |code, value|
      parent_package = PackageType.find_by(code: code)

      if(value[:default_packages])
        default_packages = value[:default_packages].gsub(" ", "").split(",")
        default_packages.each do |default_package|
          child_package = PackageType.find_by(code: default_package)
          SubpackageType.create(
            package_type: parent_package,
            child_package_type: child_package,
            is_default: true)
        end
      end

      if(value[:other_packages])
        other_packages = value[:other_packages].gsub(" ", "").split(",")
        other_packages.each do |other_package|
          child_package = PackageType.find_by(code: other_package)
          SubpackageType.create(
            package_type: parent_package,
            child_package_type: child_package)
        end
      end
    end

    ActiveRecord::Base.connection.execute(
      "UPDATE packages SET package_type_id = (
        select package_types.id
        from  package_types, item_types, packages
        where package_types.code = item_types.code and packages.package_type_id = item_types.id
        LIMIT 1
      )"
    )

    ActiveRecord::Base.connection.execute(
      "UPDATE items SET item_type_id = (
        select package_types.id
        from  package_types, item_types, packages
        where package_types.code = item_types.code and items.item_type_id = item_types.id
        LIMIT 1
      )"
    )
  end
end
