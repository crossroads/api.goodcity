class AddAvatarToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :image_id, :integer
  end
end
