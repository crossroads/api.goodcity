class RemoveQuantityField < ActiveRecord::Migration[4.2]
  def change
    remove_column :packages, :quantity, :integer
  end
end
