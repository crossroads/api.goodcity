class FixBadIndexes < ActiveRecord::Migration
  def change
    # Booking Types
    remove_index :booking_types, column: [:name_en, :name_zh_tw], unique: true
    add_index :booking_types, :identifier, unique: true
  end
end
