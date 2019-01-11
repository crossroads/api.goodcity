class AddBookingTypeIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :booking_type_id, :integer
  end
end
