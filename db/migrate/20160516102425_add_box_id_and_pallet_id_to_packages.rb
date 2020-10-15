class AddBoxIdAndPalletIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :box_id, :integer
    add_column :packages, :pallet_id, :integer
  end
end
