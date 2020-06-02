class ChangeSubscriptionsToPolymorphic < ActiveRecord::Migration
  def up
    add_column :subscriptions, :subscribable_type, :string
    add_column :subscriptions, :subscribable_id, :int

    execute("UPDATE subscriptions SET subscribable_type = 'Offer', subscribable_id = offer_id where offer_id is NOT NULL ")
    execute("UPDATE subscriptions SET subscribable_type = 'Order', subscribable_id = order_id where order_id is NOT NULL ")

    remove_column :subscriptions, :offer_id
    remove_column :subscriptions, :order_id
  end

  def down
    add_column :subscriptions, :offer_id, :int
    add_column :subscriptions, :order_id, :int

    execute("UPDATE subscriptions SET offer_id = subscribable_id where subscribable_type = 'Offer'")
    execute("UPDATE subscriptions SET order_id = subscribable_id where subscribable_type = 'Order'")

    remove_column :subscriptions, :subscribable_type
    remove_column :subscriptions, :subscribable_id
  end
end
