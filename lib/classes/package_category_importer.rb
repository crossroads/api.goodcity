class PackageCategoryImporter
  def self.import
    categories = YAML.load_file("#{Rails.root}/db/package_categories.yml")

    categories.each do |key, value|
      parent = create_category(value)

      value[:child_categories].each do |key, value|
        create_category(value, parent)
      end
    end
  end

  def self.create_category(value, parent = nil)
    category = PackageCategory.where(name_en: value[:name_en], parent_id: parent.try(:id)).
      first_or_initialize
    category.name_zh_tw = value[:name_zh_tw]
    category.parent_id  = parent.id if parent
    category.save
    category
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
