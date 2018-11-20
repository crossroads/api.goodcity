
class BookingType < ActiveRecord::Base
	has_many :order_transports

	def self.appointment
		BookingType.find_by(name_en: "Appointment")
	end

end