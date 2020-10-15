class ConvertImageToImageId < ActiveRecord::Migration[4.2]
  def change
    rename_column :images, :image, :image_id
  end
end
