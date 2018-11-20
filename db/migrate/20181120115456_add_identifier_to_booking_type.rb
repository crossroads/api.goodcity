class AddIdentifierToBookingType < ActiveRecord::Migration
  def change
    add_column :booking_types, :identifier, :string
  end
end
