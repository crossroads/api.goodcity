class AddSetItemIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :set_item_id, :integer
  end
end
