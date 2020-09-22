class AddBookingTypeIdToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :booking_type_id, :integer
  end
end
