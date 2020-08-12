class RemovePermissionIdFromUser < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :permission_id
  end
end
