class RemovePrinterId < ActiveRecord::Migration
  def up
    create_table :printers_users do |t|
      t.integer :printer_id
      t.integer :user_id
      t.string  :tag
    end
    execute("INSERT INTO printers_users(printer_id, user_id, tag) SELECT printer_id, id, 'stock' FROM users WHERE users.printer_id IS NOT NULL")
    remove_column :users, :printer_id, :integer
  end

  def down
    add_column :users, :printer_id, :integer
    execute("UPDATE users SET printer_id=printers_users.printer_id FROM printers_users WHERE users.id=printers_users.user_id AND printers_users.tag='stock'")
    drop_table :printers_users
  end
end