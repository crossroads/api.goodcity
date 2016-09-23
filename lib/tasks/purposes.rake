namespace :goodcity do

  # rake goodcity:add_purposes
  desc 'Add Purposes list'
  task add_purposes: :environment do
    purposes = YAML.load_file("#{Rails.root}/db/purposes.yml")
    purposes.each do |key, value|
      holiday = Purpose.where(
        name_en: value[:name_en],
        name_zh_tw: value[:name_zh_tw],
      ).first_or_create
    end
  end

end
