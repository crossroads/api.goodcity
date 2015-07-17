class PackageCategoryImporter
  def self.import
    categories = YAML.load_file("#{Rails.root}/db/package_categories.yml")

    categories.each do |key, value|
      parent = PackageCategory.create name_en: value[:name_en]

      value[:child_categories].each do |key, value|
        PackageCategory.create(name_en: value[:name_en], parent_id: parent.id)
      end
    end
  end

  def self.import_package_relation
    categories = YAML.load_file("#{Rails.root}/db/package_categories_package_type.yml")
    categories.each do |name, value|
      package = PackageType.find_by(code: value[:code])
      package_category = PackageCategory.find_by(name_en: value[:lv2])

      if package && package_category
        PackageCategoriesPackageType.create(
          package_type_id:     package.id,
          package_category_id: package_category.id
        )
      end
    end
  end
end
