class AddFavouriteImageIdToPackages < ActiveRecord::Migration
  def up
    add_column :packages, :favourite_image_id, :integer
    remove_column :packages, :image_id
  end

  def down
    remove_column :packages, :favourite_image_id
    add_column :packages, :image_id, :integer
  end
end
