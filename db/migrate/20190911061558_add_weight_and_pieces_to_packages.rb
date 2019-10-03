class AddWeightAndPiecesToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :weight, :integer
    add_column :packages, :pieces, :integer
  end
end
