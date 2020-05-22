class AddPrinterForeignKeyToUser < ActiveRecord::Migration
  def change
    add_foreign_key :users, :printers
  end
end
