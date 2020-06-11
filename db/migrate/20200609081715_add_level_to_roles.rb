class AddLevelToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :level, :integer
  end
end
