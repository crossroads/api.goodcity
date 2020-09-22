class AddIdentifierToBookingType < ActiveRecord::Migration[4.2]
  def change
    add_column :booking_types, :identifier, :string
  end
end
