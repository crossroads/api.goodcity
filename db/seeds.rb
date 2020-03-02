# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

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
cancellation_reasons.each do |name_en, value|
  FactoryBot.create(:cancellation_reason,
    name_en: name_en,
    name_zh_tw: value[:name_zh_tw],
    visible_to_admin: value[:visible_to_admin] )
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
    allow_stock: true )
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
  StorageType.find_or_create_by(storage_type)
end

# Create PackageCategories
PackageCategoryImporter.import

# Create PackageCategoriesPackageType
PackageCategoryImporter.import_package_relation

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

# Identity types
id_types = YAML.load_file("#{Rails.root}/db/identity_types.yml")
id_types.each_value do |record|
  IdentityType.find_or_create_by(record)
end

# Create System User
FactoryBot.create(:user, :system)

# Create API User
FactoryBot.create(:user, :api_user, first_name: "api", last_name: "write")

# Don't run the following setup on the live server.
# This is for dummy data
unless ENV['LIVE'] == "true"

  donor_attributes = [
    { mobile: "+85251111111", first_name: "David", last_name: "Dara51" },
    { mobile: "+85251111112", first_name: "Daniel", last_name: "Dell52" },
    { mobile: "+85251111113", first_name: "Dakota", last_name: "Deryn53" },
    { mobile: "+85251111114", first_name: "Delia", last_name: "Devon54" },
    { mobile: "+85241111111", first_name: "Daemon", last_name: "Dara55" },
    { mobile: "+85241111112", first_name: "Daniela", last_name: "Dell56" },
    { mobile: "+85241111113", first_name: "Duke", last_name: "Deryn57" },
    { mobile: "+85241111114", first_name: "Dave", last_name: "Devon58" },
  ]
  donor_attributes.each {|attr| FactoryBot.create(:user, attr) }

  reviewer_attributes = [
    { mobile: "+85261111111", first_name: "Rachel", last_name: "Riley61" },
    { mobile: "+85261111112", first_name: "Robyn", last_name: "Raina62" },
    { mobile: "+85261111113", first_name: "Rafael", last_name: "Ras63" },
    { mobile: "+85261111114", first_name: "Raj", last_name: "Rakim64" },
    { mobile: "+85271111111", first_name: "Robert", last_name: "Dara65" },
    { mobile: "+85271111112", first_name: "Richard", last_name: "Dell66" },
    { mobile: "+85271111113", first_name: "Robil", last_name: "Deryn67" },
    { mobile: "+85271111114", first_name: "Richa", last_name: "Devon68" },
  ]
  reviewer_attributes.each {|attr| FactoryBot.create(:user, :reviewer, attr) }

  supervisor_attributes = [
    { mobile: "+85291111111", first_name: "Sarah", last_name: "Sahn91" },
    { mobile: "+85291111112", first_name: "Sally", last_name: "Salwa92" },
    { mobile: "+85291111113", first_name: "Saad", last_name: "Safa93" },
    { mobile: "+85291111114", first_name: "Scott", last_name: "Sandro94" },
    { mobile: "+85281111111", first_name: "Steve", last_name: "Sahn95" },
    { mobile: "+85281111112", first_name: "Smith", last_name: "Salwa96" },
    { mobile: "+85281111113", first_name: "Scarlett", last_name: "Safa97" },
    { mobile: "+85281111114", first_name: "Sky", last_name: "Sandro98" },
  ]
  supervisor_attributes.each {|attr| FactoryBot.create(:user, :supervisor, attr) }

  charity_attributes = [
    { mobile: "+85252222221", first_name: "Chris", last_name: "Chan521" },
    { mobile: "+85252222222", first_name: "Charlotte", last_name: "Cheung522" },
    { mobile: "+85252222223", first_name: "Charis", last_name: "Chen523" },
    { mobile: "+85252222224", first_name: "Carlos", last_name: "Chung524" },
    { mobile: "+85242222221", first_name: "Christian", last_name: "Chan525" },
    { mobile: "+85242222222", first_name: "Charlie", last_name: "Cheung526" },
    { mobile: "+85242222223", first_name: "Cathie", last_name: "Chen527" },
    { mobile: "+85242222224", first_name: "Cally", last_name: "Chung528" },
  ]
  charity_attributes.each {|attr| FactoryBot.create(:user, :charity, attr) }

  order_fulfiler_attributes = [
    { mobile: "+85262222221", first_name: "Olive", last_name: "Oakley621" },
    { mobile: "+85262222222", first_name: "Owen", last_name: "Ogilvy622" },
    { mobile: "+85262222223", first_name: "Oscar", last_name: "O'Riley623" },
    { mobile: "+85262222224", first_name: "Octavia", last_name: "O'Connor624" },
    { mobile: "+85272222221", first_name: "Oswald", last_name: "Oakley625" },
    { mobile: "+85272222222", first_name: "Ohio", last_name: "Ogilvy626" },
    { mobile: "+85272222223", first_name: "Omen", last_name: "O'Riley627" },
    { mobile: "+85272222224", first_name: "Owie", last_name: "O'Connor628" },
  ]
  order_fulfiler_attributes.each {|attr| FactoryBot.create(:user, :order_fulfilment, attr) }

  order_administrator_attributes = [
    { mobile: "+85263333331", first_name: "Fred", last_name: "Mercury631" },
    { mobile: "+85263333332", first_name: "Freddy", last_name: "Mercury632" },
    { mobile: "+85263333333", first_name: "Frederic", last_name: "Mercury633" },
    { mobile: "+85263333334", first_name: "Fredd", last_name: "Mercury634" },
    { mobile: "+85273333331", first_name: "Fredie", last_name: "Mercury635" },
    { mobile: "+85273333332", first_name: "Franky", last_name: "Mercury636" },
    { mobile: "+85273333333", first_name: "Frank", last_name: "Mercury637" },
    { mobile: "+85273333334", first_name: "Felicia", last_name: "Mercury638" },
  ]
  order_administrator_attributes.each {|attr| FactoryBot.create(:user, :order_administrator, attr) }
end


# Might be worth adding the following rake tasks:
#   rake goodcity:import_swd_organisations
#   rake goodcity:populate_organisations
