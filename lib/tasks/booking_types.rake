#rake goodcity:booking_types
namespace :goodcity do
  desc 'Initialize the different booking types'
  task booking_types: :environment do
    booking_types = YAML.load_file("#{Rails.root}/db/booking_types.yml")
    booking_types.each_value do |record|
      BookingType.find_or_create_by(record)
    end
  end
end
