#rake goodcity:create_identity_types
namespace :goodcity do
  desc 'Initialize the different identity types'
  task create_identity_types: :environment do
    id_types = YAML.load_file("#{Rails.root}/db/identity_types.yml")
    id_types.each_value do |record|
      IdentityType.find_or_create_by(record)
    end
  end
end
