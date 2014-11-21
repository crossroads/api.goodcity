class ImageColumnChanges < ActiveRecord::Migration
  def change
    rename_column :images, :parent_id, :item_id
    rename_column :images, :image_id, :cloudinary_id
    remove_column :images, :parent_type
    remove_column :images, :order
  end
end
