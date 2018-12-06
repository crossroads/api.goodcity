
class BookingType < ActiveRecord::Base
	has_many :order_transports

	def self.appointment
		BookingType.find_by(identifier: "appointment")
	end

end