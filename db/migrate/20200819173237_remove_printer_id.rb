class RemovePrinterId < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :printer_id, :integer
  end

  def down
    add_column :users, :printer_id, :integer
    execute("UPDATE users SET printer_id=printers_users.printer_id FROM printers_users WHERE users.id=printers_users.user_id AND printers_users.tag='stock'")
    drop_table :printers_users
  end
end
