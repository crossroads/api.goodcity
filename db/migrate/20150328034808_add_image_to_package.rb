class AddImageToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :image_id, :integer
  end
end
