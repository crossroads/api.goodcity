class ChangeSubscriptionsToPolymorphic < ActiveRecord::Migration
  def up
    # add_column :subscriptions, :subscribable_type, :string
    # add_column :subscriptions, :subscribable_id, :int

    # Subscription.all.map do |subs|
    #   if subs.offer_id
    #     offer = subs.offer
    #     subs.subscribable_type = offer.class.name
    #     subs.subscribable_id = offer.id
    #   elsif subs.order_id
    #     order = subs.order
    #     subs.subscribable_type = order.class.name
    #     subs.subscribable_id = order.id
    #   end
    #   subs.save!(validate: false)
    # end

    remove_column :subscriptions, :offer_id
    remove_column :subscriptions, :order_id
  end

  # def down
  #   add_column :subscriptions, :offer_id, :int
  #   add_column :subscriptions, :order_id, :int

  #   Subscription.all.map do |subs|
  #     case subs.subscribable_type
  #     when 'Offer'
  #       subs.offer_id = subs.subscribable_id
  #     when 'Order'
  #       subs.order_id = subs.subscribable_id
  #     end
  #   end

  #   remove_column :subscriptions, :subscribable_type
  #   remove_column :subscriptions, :subscribable_id
  # end
end
