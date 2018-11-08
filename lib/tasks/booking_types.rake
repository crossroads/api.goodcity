#rake goodcity:booking_types
namespace :goodcity do
	desc 'Add or Update Rejection Reasons'
	task booking_types: :environment do 
		booking_types = YAML.load_file("#{Rails.root}/db/booking_types.yml")
    booking_types.each do |name_en, value|
      BookingType.where(
        name_en: name_en,
        name_zh_tw: value[:name_zh_tw]
      ).first_or_create
    end
	end
end
