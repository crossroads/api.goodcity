class AddAllowExpiryDateToPackageTypes < ActiveRecord::Migration
  def change
    add_column :package_types, :allow_expiry_date, :boolean, default: false
  end
end
