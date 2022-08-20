# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
# Use rake db:demo for test data once this task has run

# Donor Conditions
donor_conditions = YAML.load_file("#{Rails.root}/db/donor_conditions.yml")
donor_conditions.each do |name, value|
  DonorCondition.create(
    name_en: name,
    name_zh_tw: value[:name_zh_tw],
    visible_to_donor: value[:visible_to_donor]
  )
end

# Rejection Reasons
rejection_reasons = YAML.load_file("#{Rails.root}/db/rejection_reasons.yml")
rejection_reasons.each do |name_en, value|
  RejectionReason.create(
    name_en: name_en,
    name_zh_tw: value[:name_zh_tw]
  )
end

# Cancellation Reasons
cancellation_reasons = YAML.load_file("#{Rails.root}/db/cancellation_reasons.yml")
cancellation_reasons.each do |name_en, attrs|
  CancellationReason.create!(name_en: name_en, **attrs)
end

# Booking Types
booking_types = YAML.load_file("#{Rails.root}/db/booking_types.yml")
booking_types.each do |identifier, value|
  BookingType.create(
    identifier: identifier,
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw]
  )
end

# Process Checklists
process_checklists = YAML.load_file("#{Rails.root}/db/process_checklists.yml")
process_checklists.each do |booking_type, values|
  @booking_type = BookingType.find_by_identifier(booking_type)
  values.each do |attrs|
    ProcessChecklist.create(
      booking_type: @booking_type,
      text_en: attrs[:text_en],
      text_zh_tw: attrs[:text_zh_tw]
    )
  end
end

# Territories
territories = YAML.load_file("#{Rails.root}/db/territories.yml")
territories.each do |name_en, value|
  Territory.create(
    name_en: name_en,
    name_zh_tw: value[:name_zh_tw]
  )
end

# Districts
districts = YAML.load_file("#{Rails.root}/db/districts.yml")
districts.each do |name_en, value|
  District.create(
    name_en: name_en,
    name_zh_tw: value[:name_zh_tw],
    latitude: value[:latitude],
    longitude: value[:longitude],
    territory_id: Territory.find_by_name_en(value[:territory_name_en]).id
  )
end

# Timeslots
timeslots = [["10:30am-1pm", "上午10:30時至下午1時"], ["2PM-4PM", "下午2時至下午4時"]]
timeslots.each do |timeslot|
  Timeslot.create(
    name_en: timeslot.first,
    name_zh_tw: timeslot.last
  )
end

# GogovanTransports
gogovan_transports = YAML.load_file("#{Rails.root}/db/gogovan_transports.yml")
gogovan_transports.each do |name, value|
  GogovanTransport.create(
    name_en: name,
    name_zh_tw: value[:name_zh_tw],
    disabled: value[:disabled]
  )
end

# Crossroads Transports
crossroads_transports = YAML.load_file("#{Rails.root}/db/crossroads_transports.yml")
crossroads_transports.each do |name, value|
  CrossroadsTransport.create(
    name_en: name,
    name_zh_tw: value[:name_zh_tw],
    cost: value[:cost],
    truck_size: value[:truck_size],
    is_van_allowed: value[:is_van_allowed]
  )
end

# Holidays
holidays = YAML.load_file("#{Rails.root}/db/holidays.yml")
holidays.each do |key, value|
  date_value = DateTime.parse(value[:holiday]).in_time_zone(Time.zone)
  holiday = Holiday.create(
    name: value[:name],
    year: value[:year],
    holiday: date_value
  )
end
Holiday.create(name: "Christmas Day", holiday: Time.new(Time.now.year,12,25).to_date, year: Time.now.year)
Holiday.create(name: "Boxing Day", holiday: Time.new(Time.now.year,12,26).to_date, year: Time.now.year)

# Organisation Types
organisation_types = YAML.load_file("#{Rails.root}/db/organisation_types.yml")
organisation_types.each do |value|
  OrganisationType.create(
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw],
    category_en: value[:category_en],
    category_zh_tw: value[:category_zh_tw]
  )
end

# Package Types
package_types = YAML.load_file("#{Rails.root}/db/package_types.yml")
package_types.each do |code, value|
  PackageType.create(
    code: code,
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw],
    other_terms_en: value[:other_terms_en],
    other_terms_zh_tw: value[:other_terms_zh_tw],
    allow_expiry_date: value[:allow_expiry_date],
    visible_in_selects: value[:visible_in_selects],
    allow_package: value[:allow_package],
    default_value_hk_dollar: value[:default_value_hk_dollar],
    allow_box: value[:allow_box],
    allow_pallet: value[:allow_pallet],
    description_en: value[:description_en],
    description_zh_tw: value[:description_zh_tw],
    length: value[:length],
    width: value[:width],
    height: value[:height],
    customs_value_usd: value[:customs_value_usd],
    subform: value[:subform]
  )
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

# Purposes
purposes = YAML.load_file("#{Rails.root}/db/purposes.yml")
purposes.each do |key, value|
  Purpose.create(
    name_en: value[:name_en],
    name_zh_tw: value[:name_zh_tw],
    identifier: value[:identifier]
  )
end

# GoodCity Settings
goodcity_settings = YAML.load_file("#{Rails.root}/db/goodcity_settings.yml")
goodcity_settings.each do |record|
  GoodcitySetting.find_or_create_by(record)
end

# Lookups
lookups = YAML.load_file("#{Rails.root}/db/lookups.yml")
lookups.each do |record|
  Lookup.find_or_create_by(record)
end

# Printers
printers = YAML.load_file("#{Rails.root}/db/printers.yml")
printers.each do |record|
  Printer.find_or_create_by(record)
end

# Locations
locations = YAML.load_file("#{Rails.root}/db/locations.yml")
locations.each do |record|
  Location.find_or_create_by(record)
end

# Storage Types
storage_types = YAML.load_file("#{Rails.root}/db/storage_types.yml")
storage_types.each do |storage_type|
  StorageType.where(name: storage_type["name"]).first_or_create(storage_type)
end

# Create PackageCategories
PackageCategoryImporter.import

# Create PackageCategoriesPackageType
PackageCategoryImporter.import_package_relation

# Roles
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
  donor_condition_id = DonorCondition.find_by_name_en(valuation['donor_condition_name_en']).id
  ValuationMatrix.find_or_create_by(
    donor_condition_id: donor_condition_id,
    grade: valuation['grade'],
    multiplier: valuation['multiplier']
  )
end

# Identity types
identity_types = YAML.load_file("#{Rails.root}/db/identity_types.yml")
identity_types.each do |identifier, record|
  IdentityType.create(
    identifier: identifier,
    name_en: record[:name_en],
    name_zh_tw: record[:name_zh_tw]
  )
end

# Countries
countries = YAML.load_file("#{Rails.root}/db/countries.yml")
countries.each do |name_en|
  Country.create(name_en: name_en)
end

# Create System User
User.create(
  first_name: "GoodCity",
  last_name: "Team",
  mobile: SYSTEM_USER_MOBILE,
  role_ids: [Role.find_by_name("System").id]
)

# Appointment Slot Presets: Tuesday to Saturday
(2..6).each do |day|
  AppointmentSlotPreset.create(
    day: day,
    quota: 3,
    hours: 10,
    minutes: 0
  )
  AppointmentSlotPreset.create(
    day: day,
    quota: 3,
    hours: 14,
    minutes: 0
  )
end

# Load views
# This does NO SQL sanitization so run advisedly.
Dir[File.join(Rails.root, "db", "views", "*.sql")].each do |file|
  ActiveRecord::Base.connection.execute( File.read(file) )
end
