class CreateStockitContacts < ActiveRecord::Migration
  def change
    create_table :stockit_contacts do |t|
      t.string :first_name
      t.string :last_name
      t.string :mobile_phone_number
      t.string :phone_number
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
