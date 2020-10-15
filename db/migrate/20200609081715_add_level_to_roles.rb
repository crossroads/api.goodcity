class AddLevelToRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :roles, :level, :integer
    add_index :roles, :level
  end
end
