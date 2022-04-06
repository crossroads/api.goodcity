class AddCustomsValueToPackageType < ActiveRecord::Migration[6.1]
  def change
    add_column :package_types, :customs_value_usd, :decimal, default: nil
  end
end
