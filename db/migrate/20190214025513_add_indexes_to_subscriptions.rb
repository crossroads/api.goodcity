class AddIndexesToSubscriptions < ActiveRecord::Migration
  def change
    add_index :subscriptions, :state
    add_index :subscriptions, :offer_id
    add_index :subscriptions, :user_id
    add_index :subscriptions, :message_id
  end
end
