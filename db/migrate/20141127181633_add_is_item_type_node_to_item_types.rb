class AddIsItemTypeNodeToItemTypes < ActiveRecord::Migration
  def change
    add_column :item_types, :is_item_type_node, :boolean, null: false, default: false
  end
end
