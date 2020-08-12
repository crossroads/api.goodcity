class AddImageToPackage < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :image_id, :integer
  end
end
