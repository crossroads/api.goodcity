class SetImageFavouriteDefaultToFalse < ActiveRecord::Migration
  def change
    change_column_default :images, :favourite, false
  end
end
