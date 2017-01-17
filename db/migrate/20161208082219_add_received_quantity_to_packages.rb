class AddReceivedQuantityToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :received_quantity, :integer
  end
end
