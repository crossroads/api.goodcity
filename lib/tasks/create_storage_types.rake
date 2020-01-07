namespace :goodcity do
  # rake goodcity:create_storage_types
  desc "Create Storage types"
  task create_storage_types: :environment do
    storage_types = YAML.load_file("#{Rails.root}/db/storage_types.yml")
    storage_types.each do |storage_type|
      StorageType.where(name: storage_type["name"]).first_or_create(storage_type)
    end
  end
end
