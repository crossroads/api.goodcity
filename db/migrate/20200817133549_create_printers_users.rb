class CreatePrintersUsers < ActiveRecord::Migration
  def change
    create_table :printers_users do |t|
      t.integer :printer_id
      t.integer :user_id
      t.string  :tag
    end
  end
end