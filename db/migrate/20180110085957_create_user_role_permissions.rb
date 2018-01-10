class CreateUserRolePermissions < ActiveRecord::Migration
  def change
    create_table :user_role_permissions do |t|
      t.integer :user_id
      t.integer :role_id
      t.integer :permission_id

      t.timestamps null: false
    end
  end
end
