class SetImageFavouriteDefaultToFalse < ActiveRecord::Migration[4.2]
  def change
    change_column_default :images, :favourite, false
  end
end
