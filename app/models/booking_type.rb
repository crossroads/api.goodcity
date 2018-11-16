
class BookingType < ActiveRecord::Base
	has_many :order_transports
end