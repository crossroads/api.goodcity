class CreateJoinTableForSubscriptions < ActiveRecord::Migration
  def change
    create_join_table :users, :messages, table_name: :subscriptions do |t|
        t.index([:user_id, :message_id], unique: true, name: 'user_message')
    end
  end
end
