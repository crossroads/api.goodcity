class ChangePackageWeightToDecimal < ActiveRecord::Migration[6.1]
  def change
    change_column :packages, :weight, :decimal
  end
end
