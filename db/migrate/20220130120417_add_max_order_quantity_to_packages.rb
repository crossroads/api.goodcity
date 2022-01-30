class AddMaxOrderQuantityToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column  :packages, :max_order_quantity, :integer, :null => true, default: nil
  end
end
