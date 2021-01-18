class AddUniqueConstraintsToOrderOnTransport < ActiveRecord::Migration[5.2]
  def change
    remove_index :order_transports, :order_id
    add_index :order_transports, :order_id, unique: true
  end
end
