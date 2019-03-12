class RemoveBookingTypeIdFromOrderTransport < ActiveRecord::Migration
  def change
    remove_column :order_transports, :booking_type_id
  end
end
