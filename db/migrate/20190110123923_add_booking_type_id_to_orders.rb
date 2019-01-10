class AddBookingTypeIdToOrders < ActiveRecord::Migration
  def change
    add_reference :orders, :booking_type, index: true, foreign_key: true
  end
end
