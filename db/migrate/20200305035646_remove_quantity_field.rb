class RemoveQuantityField < ActiveRecord::Migration
  def change
    remove_column :packages, :quantity, :integer
  end
end
