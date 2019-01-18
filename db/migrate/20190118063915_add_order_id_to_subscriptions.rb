class AddOrderIdToSubscriptions < ActiveRecord::Migration
  def change
    add_reference :subscriptions, :order, index: true, foreign_key: true
  end
end
