class CreatePrinters < ActiveRecord::Migration
  def change
    create_table :printers do |t|
      t.boolean :active
      t.integer :location_id
      t.string :name
      t.string :host
      t.string :port
      t.string :username
      t.string :password

      t.timestamps null: false
    end
  end
end
