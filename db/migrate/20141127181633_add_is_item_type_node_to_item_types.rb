class AddIsItemTypeNodeToItemTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :item_types, :is_item_type_node, :boolean, null: false, default: false
  end
end
