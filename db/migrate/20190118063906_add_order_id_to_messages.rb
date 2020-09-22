class AddOrderIdToMessages < ActiveRecord::Migration[4.2]
  def change
    add_reference :messages, :order, index: true, foreign_key: true
  end
end
