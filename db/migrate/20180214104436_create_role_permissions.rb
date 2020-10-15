class CreateRolePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :role_permissions do |t|
      t.integer :role_id
      t.integer :permission_id

      t.timestamps null: false
    end
  end
end
