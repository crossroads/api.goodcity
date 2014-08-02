class ConvertImageToImageId < ActiveRecord::Migration
  def change
    rename_column :images, :image, :image_id
  end
end
