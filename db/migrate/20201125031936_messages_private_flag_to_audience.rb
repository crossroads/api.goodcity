class MessagesPrivateFlagToAudience < ActiveRecord::Migration[5.2]
  def up
    add_column :messages, :audience, :string

    sql %{ UPDATE messages SET audience = 'donor' WHERE is_private = false }
    sql %{ UPDATE messages SET audience = 'staff' WHERE is_private != false }

    change_column_null :messages, :audience, false
    remove_column :messages, :is_private
  end

  def down
    add_column :messages, :is_private, :boolean

    sql %{ UPDATE messages SET is_private = FALSE WHERE audience = 'donor' }
    sql %{ UPDATE messages SET is_private = TRUE WHERE audience != 'donor' }

    remove_column :messages, :audience
  end

  private

  def sql(query)
    ActiveRecord::Base.connection.execute(query);
  end
end
