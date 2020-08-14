class AddExpiryDateToUserRoles < ActiveRecord::Migration
  def change
    add_column :user_roles, :expiry_date, :date
  end
end
