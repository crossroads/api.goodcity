class AddAngleToImages < ActiveRecord::Migration
  def change
    add_column :images, :angle, :integer, default: 0
  end
end
