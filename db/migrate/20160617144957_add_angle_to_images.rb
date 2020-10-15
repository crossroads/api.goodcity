class AddAngleToImages < ActiveRecord::Migration[4.2]
  def change
    add_column :images, :angle, :integer, default: 0
  end
end
