class AddExtraQuantityFields < ActiveRecord::Migration[4.2]
  def change
    add_column    :packages, :available_quantity,   :integer, default: 0
    add_column    :packages, :on_hand_quantity,     :integer, default: 0
    add_column    :packages, :designated_quantity,  :integer, default: 0
    add_column    :packages, :dispatched_quantity,  :integer, default: 0

    add_index :packages, :available_quantity
    add_index :packages, :on_hand_quantity
    add_index :packages, :designated_quantity
    add_index :packages, :dispatched_quantity
  end
end
