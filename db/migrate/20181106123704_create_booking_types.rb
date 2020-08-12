class CreateBookingTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :booking_types do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps null: false
    end
  end
end
