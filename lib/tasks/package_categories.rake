namespace :goodcity do

  # rake goodcity:add_package_categories
  desc 'add_package_categories'
  task add_package_categories: :environment do

    categories = {
      "Electrical" => ["Computer", "Household", "Kitchen", "Other electrical",
        "Audio visual", "Office appliances"],

      "Furniture" => ["Baby / child", "Beds", "Desk", "Seating", "Shelves",
        "Storage", "Table", "Other furniture", "Office furniture", "Sets"],

      "Household" => ["Appliances", "Baby", "Textiles / clothes",
        "Kitchen, bedroom, bathroom, dining",  "Other household"],

      "Small goods & bulk items" => ["Books", "Food", "Glasses", "Stationery",
        "Tools", "Toys", "Medical", "Clothing & accessories",
        "Mixed / miscellaneous", "Household textiles"],

      "Recreation" => ["Music", "Other", "Playground", "Sport", "Bicycles"]
    }

    categories.each do |category, types|
      parent = PackageCategory.create name_en: category

      types.each do |type|
        PackageCategory.create(name_en: type, parent_id: parent.id)
      end
    end

  end

  # rake goodcity:add_package_sub_categories
  desc 'add_package_sub_categories'
  task add_package_sub_categories: :environment do

    categories = YAML.load_file("#{Rails.root}/db/package_sub_categories.yml")
    categories.each do |name, value|
      package = PackageType.find_by(code: value[:code])
      package_category = PackageCategory.find_by(name_en: value[:lv2])

      if package && package_category
        PackageSubCategory.create(
          package_type_id:     package.id,
          package_category_id: package_category.id
        )
      end
    end

  end
end
