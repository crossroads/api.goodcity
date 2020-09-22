class AddAllowExpiryDateToPackageTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :allow_expiry_date, :boolean, default: false
  end
end
