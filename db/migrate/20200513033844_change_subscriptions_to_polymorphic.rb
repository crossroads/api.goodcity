class ChangeSubscriptionsToPolymorphic < ActiveRecord::Migration
  def up
    add_column :subscriptions, :subscribable_type, :string
    add_column :subscriptions, :subscribable_id, :int

    ActiveRecord::Base.transaction do
      Subscription.all.map do |subs|
        if subs.offer_id
          offer = subs.offer
          subs.subscribable_type = offer.class.name
          subs.subscribable_id = offer.id
        elsif subs.order_id
          order = subs.order
          subs.subscribable_type = order.class.name
          subs.subscribable_id = order.id
        end
        subs.save!(validate: false)
      end
    end
  end

  def down
    remove_column :subscriptions, :subscribable_type
    remove_column :subscriptions, :subscribable_id
  end
end
