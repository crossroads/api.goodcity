class CreatePrintersUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :printers_users do |t|
      t.integer :printer_id
      t.integer :user_id
      t.string  :tag
    end
    execute("INSERT INTO printers_users(printer_id, user_id, tag) SELECT printer_id, id, 'stock' FROM users WHERE users.printer_id IS NOT NULL")
  end
end
