class CreateUserFavourites < ActiveRecord::Migration[5.2]
  def change
    create_table :user_favourites do |t|
      t.string    :favourite_type, index: true
      t.integer   :favourite_id
      t.integer   :user_id
      t.boolean   :persistent, default: false 

      t.timestamps
    end

    add_index :user_favourites, [:favourite_type, :favourite_id], unique: true
    add_foreign_key :user_favourites, :users, column: :user_id
    add_index :user_favourites, [:favourite_id, :favourite_type], unique: true
    add_index :user_favourites, :updated_at
  end
end
