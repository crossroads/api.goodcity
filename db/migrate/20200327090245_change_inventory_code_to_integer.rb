class ChangeInventoryCodeToInteger < ActiveRecord::Migration
  def up
    change_column :inventory_numbers, :code, 'integer USING CAST(code as integer)'
  end

  def down
    change_column :inventory_numbers, :code, :string
  end
end
