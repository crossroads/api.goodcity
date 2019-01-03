namespace :goodcity do
  # rake goodcity:add_purposes
  desc 'Add Purposes list'
  task add_purposes: :environment do
    purposes = YAML.load_file("#{Rails.root}/db/purposes.yml")
    purposes.each_value do |record|
      Purpose.find_or_create_by(record)
    end
  end
end
