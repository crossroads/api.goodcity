namespace :goodcity do
  # rake goodcity:create_restrictions
  desc 'Add Purposes list'
  task create_restrictions: :environment do
    restrictions = YAML.load_file("#{Rails.root}/db/restrictions.yml")
    restrictions.each_value do |record|
      Restriction.find_or_create_by(record)
    end
  end
end
