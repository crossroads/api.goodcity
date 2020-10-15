class AddValuationToPackage < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :value_hk_dollar, :decimal, default: nil
    add_column :package_types, :default_value_hk_dollar, :decimal, default: nil
  end
end
