class AddExpiryDateToPackage < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :expiry_date, :date
  end
end
