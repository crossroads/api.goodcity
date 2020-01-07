#rake goodcity:booking_types
namespace :goodcity do
  desc 'Initialize the different booking types'
  task booking_types: :environment do
    booking_types = YAML.load_file("#{Rails.root}/db/booking_types.yml")
    booking_types.each do |identifier, value|
      BookingType.find_or_create_by(identifier: identifier, name_en: value[:name_en], name_zh_tw: value[:name_zh_tw])
    end
  end
end
