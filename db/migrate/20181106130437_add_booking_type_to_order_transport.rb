class AddBookingTypeToOrderTransport < ActiveRecord::Migration
  def change
    add_column :order_transports, :booking_type_id, :integer
  end
end