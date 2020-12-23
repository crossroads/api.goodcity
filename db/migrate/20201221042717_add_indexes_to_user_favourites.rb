class AddIndexesToUserFavourites < ActiveRecord::Migration[5.2]
  def change
    remove_index :user_favourites, [:favourite_type, :favourite_id]
    remove_index :user_favourites, [:favourite_id, :favourite_type]
    add_index :user_favourites, [:user_id, :favourite_type, :favourite_id], unique: true, name: 'index_user_and_favourites'
  end
end
