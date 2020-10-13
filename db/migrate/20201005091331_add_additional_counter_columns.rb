class AddAdditionalCounterColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :packages, :on_hand_boxed_quantity, :integer, default: 0
    add_column :packages, :on_hand_palletized_quantity, :integer, default: 0
  end
end
