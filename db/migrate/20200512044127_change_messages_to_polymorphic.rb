class ChangeMessagesToPolymorphic < ActiveRecord::Migration
  def up
    add_column :messages, :messageable_type, :string
    add_column :messages, :messageable_id, :int
    Message.all.map do |message|
      if message.item_id
        item = message.item
        message.messageable_type = item.class.name
        message.messageable_id = item.id
      elsif message.offer_id
        offer = message.offer
        message.messageable_type = offer.class.name
        message.messageable_id = offer.id
      elsif message.order_id
        order = message.order
        message.messageable_type = order.class.name
        message.messageable_id = order.id
      end
      message.save!(validate: false)
    end

    remove_column :messages, :offer_id
    remove_column :messages, :order_id
    remove_column :messages, :item_id
  end

  def down
    add_column :messages, :offer_id, :int
    add_column :messages, :order_id, :int
    add_column :messages, :item_id, :int

    Message.all.map do |message|
      case message.messageable_id
      when 'Order'
        message.order_id = message.messageable_id
      when 'Offer'
        message.offer_id = message.messageable_id
      when 'Item'
        message.item_id = message.messageable_id
        message.offer_id = message.messageable.offer.id
      end
    end
    remove_column :messages, :messageable_type
    remove_column :messages, :messageable_id
  end
end
