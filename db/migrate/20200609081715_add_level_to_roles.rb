class AddLevelToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :level, :integer
    add_index :roles, :level
  end
end
