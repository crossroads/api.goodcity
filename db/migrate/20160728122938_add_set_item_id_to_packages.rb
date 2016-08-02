class AddSetItemIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :set_item_id, :integer
  end
end
