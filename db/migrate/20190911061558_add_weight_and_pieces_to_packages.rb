class AddWeightAndPiecesToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :weight, :integer
    add_column :packages, :pieces, :integer
  end
end
