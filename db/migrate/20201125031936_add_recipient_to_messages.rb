class AddRecipientToMessages < ActiveRecord::Migration[5.2]
  def up
    add_column :messages, :recipient_id, :integer, index: true
    add_foreign_key :messages, :users, column: :recipient_id

    sql <<-SQL
      UPDATE messages
      SET recipient_id = offers.created_by_id
      FROM offers 
      WHERE offers.id = messageable_id
        AND messageable_type = 'Offer'
        AND is_private != true
    SQL

    sql <<-SQL
      UPDATE messages
      SET recipient_id = offers.created_by_id
      FROM offers, items 
        WHERE items.id = messageable_id AND offers.id = items.offer_id
        AND messageable_type = 'Item'
        AND is_private != true
    SQL

    sql <<-SQL
      UPDATE messages
      SET recipient_id = orders.created_by_id
      FROM orders 
      WHERE orders.id = messageable_id
        AND messageable_type = 'Order'
        AND is_private != true
    SQL
  end

  def down
    remove_column :messages, :recipient_id
  end

  private

  def sql(query)
    ActiveRecord::Base.connection.execute(query);
  end
end
