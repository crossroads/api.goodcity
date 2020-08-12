class AddUniquenessConstraintToBookingTypes < ActiveRecord::Migration[4.2]
  def change
    add_index :booking_types, [:name_en, :name_zh_tw], unique: true
  end
end
