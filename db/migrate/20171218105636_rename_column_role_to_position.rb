class RenameColumnRoleToPosition < ActiveRecord::Migration[4.2]
  def change
    rename_column :organisations_users, :role, :position
  end
end
