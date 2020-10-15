class AddBookingTypeToOrderTransport < ActiveRecord::Migration[4.2]
  def change
    add_column :order_transports, :booking_type_id, :integer
  end
end
