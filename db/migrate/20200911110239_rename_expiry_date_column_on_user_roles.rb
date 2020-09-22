class RenameExpiryDateColumnOnUserRoles < ActiveRecord::Migration
  def change
    rename_column :user_roles, :expiry_date, :expires_at
  end
end
