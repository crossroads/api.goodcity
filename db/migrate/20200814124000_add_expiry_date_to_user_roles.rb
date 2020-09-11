class AddExpiryDateToUserRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :user_roles, :expiry_date, :datetime
  end
end
