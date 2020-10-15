class AddIndexesToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_index :subscriptions, :state
    add_index :subscriptions, :offer_id
    add_index :subscriptions, :user_id
    add_index :subscriptions, :message_id
  end
end
