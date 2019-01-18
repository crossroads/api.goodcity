class AddOrderIdToMessages < ActiveRecord::Migration
  def change
    add_reference :messages, :order, index: true, foreign_key: true
  end
end
