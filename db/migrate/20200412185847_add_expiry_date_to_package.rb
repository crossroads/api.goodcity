class AddExpiryDateToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :expiry_date, :date
  end
end
