class AddUniquenessConstraintToBookingTypes < ActiveRecord::Migration
  def change
    add_index :booking_types, [:name_en, :name_zh_tw], unique: true
  end
end
