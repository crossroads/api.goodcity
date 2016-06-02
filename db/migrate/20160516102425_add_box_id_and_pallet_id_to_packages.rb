class AddBoxIdAndPalletIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :box_id, :integer
    add_column :packages, :pallet_id, :integer
  end
end
