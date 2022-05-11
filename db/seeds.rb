# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
# Use rake db:demo for test data once this task has run

donor_conditions = YAML.load_file("#{Rails.root}/db/donor_conditions.yml")
donor_conditions.each do |name, value|
  FactoryBot.create(:donor_condition,
    name_en: name,
    name_zh_tw: value[:name_zh_tw] )
end

rejection_reasons = YAML.load_file("#{Rails.root}/db/rejection_reasons.yml")
rejection_reasons.each do |name_en, value|
  FactoryBot.create(:rejection_reason,
    name_en: name_en,
    name_zh_tw: value[:name_zh_tw] )
end

cancellation_reasons = YAML.load_file("#{Rails.root}/db/cancellation_reasons.yml")
cancellation_reasons.each do |name_en, attrs|
  CancellationReason.create!(name_en: name_en, **attrs)
end

booking_types = YAML.load_file("#{Rails.root}/db/booking_types.yml")
booking_types.each do |identifier, value|
  FactoryBot.create(:booking_type,
    identifier: identifier,
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw] )
end

districts = YAML.load_file("#{Rails.root}/db/districts.yml")
districts.each do |name_en, value|
  # FactoryBot creates the correct territory for us
  FactoryBot.create :district, name_en: name_en, latitude: value[:latitude], longitude: value[:longitude]
end

timeslots = [["10:30am-1pm", "上午10:30時至下午1時"], ["2PM-4PM", "下午2時至下午4時"]]
timeslots.each do |name|
  FactoryBot.create :timeslot, name_en: name.first, name_zh_tw: name.last
end

gogovan_transports = YAML.load_file("#{Rails.root}/db/gogovan_transports.yml")
gogovan_transports.each do |name, value|
  FactoryBot.create :gogovan_transport, name_en: name, name_zh_tw: value[:name_zh_tw], disabled: value[:disabled]
end

crossroads_transports = YAML.load_file("#{Rails.root}/db/crossroads_transports.yml")
crossroads_transports.each do |name, value|
  FactoryBot.create :crossroads_transport, name_en: name, name_zh_tw: value[:name_zh_tw], cost: value[:cost], truck_size: value[:truck_size]
end

CrossroadsTransport.find_by(name_en: "Disable").update_column(:is_van_allowed, false)

holidays = YAML.load_file("#{Rails.root}/db/holidays.yml")
holidays.each do |key, value|
  date_value = DateTime.parse(value[:holiday]).in_time_zone(Time.zone)
  holiday = Holiday.where(
    name: value[:name],
    year: value[:year],
    holiday: date_value
  ).first_or_create
end

organisation_types = YAML.load_file("#{Rails.root}/db/organisation_types.yml")
organisation_types.each do |key, value|
  OrganisationType.create(
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw],
    category_en: value[:category_en],
    category_zh_tw: value[:category_zh_tw] )
end

package_types = YAML.load_file("#{Rails.root}/db/package_types.yml")
package_types.each do |code, value|
  PackageType.create(
    code: code,
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw],
    other_terms_en: value[:other_terms_en],
    other_terms_zh_tw: value[:other_terms_zh_tw],
    allow_package: true,
    default_value_hk_dollar: value[:default_value_hk_dollar] )
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

purposes = YAML.load_file("#{Rails.root}/db/purposes.yml")
purposes.each do |key, value|
  holiday = Purpose.where(
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw],
  ).first_or_create
end

goodcity_settings = YAML.load_file("#{Rails.root}/db/goodcity_settings.yml")
goodcity_settings.each do |record|
  GoodcitySetting.find_or_create_by(record)
end

lookups = YAML.load_file("#{Rails.root}/db/lookups.yml")
lookups.each do |record|
  Lookup.find_or_create_by(record)
end

printers = YAML.load_file("#{Rails.root}/db/printers.yml")
printers.each do |record|
  Printer.find_or_create_by(record)
end

locations = YAML.load_file("#{Rails.root}/db/locations.yml")
locations.each do |record|
  Location.find_or_create_by(record)
end

storage_types = YAML.load_file("#{Rails.root}/db/storage_types.yml")
storage_types.each do |storage_type|
  StorageType.where(name: storage_type["name"]).first_or_create(storage_type)
end

# Create PackageCategories
PackageCategoryImporter.import

# Create PackageCategoriesPackageType
PackageCategoryImporter.import_package_relation

roles = YAML.load_file("#{Rails.root}/db/roles.yml")
roles.each do |role_name, attrs|
  if (role = Role.where(name: role_name).first_or_initialize)
    role.assign_attributes(**attrs)
    role.save
  end
end

# Permission and Role mappings
permissions_roles = YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
permissions_roles.each_pair do |role_name, permission_names|
  permission_names.flatten!
  if (role = Role.where(name: role_name).first_or_create)
    permission_names.each do |permission_name|
      permission = Permission.where(name: permission_name).first_or_create
      RolePermission.where(role: role, permission: permission).first_or_create
    end
  end
end

# Valuation matrix
valuation_matrix = YAML.load_file("#{Rails.root}/db/valuation_matrix.yml")
valuation_matrix.each do |valuation|
  donor_condition_id = DonorCondition.where(name_en: valuation['donor_condition_name_en']).first.id
  ValuationMatrix.find_or_create_by(donor_condition_id: donor_condition_id,
    grade: valuation['grade'], multiplier: valuation['multiplier'])
end

# Identity types
id_types = YAML.load_file("#{Rails.root}/db/identity_types.yml")
id_types.each_value do |record|
  IdentityType.find_or_create_by(record)
end

FactoryBot.create(:country, name_en: "China - Hong Kong (Special Administrative Region)")
100.times{ FactoryBot.create(:country) }

# Create System User
FactoryBot.create(:user, :system)

# Create API User
FactoryBot.create(:user, :api_write, first_name: "api", last_name: "write")

# Appointment Slot Presets: Tuesday to Saturday
(2..6).each do |day|
  FactoryBot.create :appointment_slot_preset, :morning, day: day
  FactoryBot.create :appointment_slot_preset, :afternoon, day: day
end
