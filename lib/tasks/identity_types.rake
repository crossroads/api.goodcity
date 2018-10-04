namespace :goodcity do
  desc 'Initialize the different identity types'
  task create_identity_types: :environment do
    id_types = YAML.load_file("#{Rails.root}/db/identity_types.yml")
    id_types.each do |index, record|
      name = record[:name]
      IdentityType.unscoped.where(name: name).first_or_create
    end
  end
end
  
  