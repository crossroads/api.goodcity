class AddImageableColumnsToImages < ActiveRecord::Migration
  def up
    add_column :images, :imageable_id, :integer
    add_column :images, :imageable_type, :string

    Image.reset_column_information
    Image.update_all(imageable_type: "Item")
    ActiveRecord::Base.connection.execute("UPDATE images SET imageable_id = item_id")

  end

  def down
    remove_column :images, :imageable_id
    remove_column :images, :imageable_type
  end
end
