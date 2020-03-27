class MakeInventoryNumberUnique < ActiveRecord::Migration
  def change
    def change
      remove_index :packages, :inventory_number
      add_index :packages, :inventory_number, unique: true
    end
  end
end
