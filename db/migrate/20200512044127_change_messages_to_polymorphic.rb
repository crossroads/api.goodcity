class ChangeMessagesToPolymorphic < ActiveRecord::Migration
  def up
    add_column :messages, :messageable_type, :string
    add_column :messages, :messageable_id, :int

    execute("UPDATE messages SET messageable_type = 'Offer', messageable_id = offer_id where offer_id is NOT NULL")
    execute("UPDATE messages SET messageable_type = 'Item', messageable_id = item_id where item_id is NOT NULL")
    execute("UPDATE messages SET messageable_type = 'Order', messageable_id = order_id where order_id is NOT NULL")

    remove_column :messages, :offer_id
    remove_column :messages, :order_id
    remove_column :messages, :item_id
  end

  def down
    add_column :messages, :offer_id, :int
    add_column :messages, :order_id, :int
    add_column :messages, :item_id, :int

    Message.all.map do |message|
      case message.messageable_type
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
