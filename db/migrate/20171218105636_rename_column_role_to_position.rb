class RenameColumnRoleToPosition < ActiveRecord::Migration
  def change
    rename_column :organisations_users, :role, :position
  end
end
