class RenameExpiryDateColumnOnUserRoles < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_roles, :expiry_date, :expires_at
  end
end
