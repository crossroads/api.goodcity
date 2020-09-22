class AddReceivedQuantityToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :received_quantity, :integer
  end
end
