class RemoveBookingTypeIdFromOrderTransport < ActiveRecord::Migration[4.2]
  def change
    remove_column :order_transports, :booking_type_id
  end
end
