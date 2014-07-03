class AddPermissionsUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :permissions_users, :id => false do |t|
      t.references :permission, :user
    end
    add_index :permissions_users, [:permission_id, :user_id], :unique => true
  end
end
