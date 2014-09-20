class UpdateJoinTablesToSubscriptions < ActiveRecord::Migration
  def change
    drop_table :subscriptions
    create_table :subscriptions do |t|
        t.references :offer
        t.references :user
        t.references :message
        t.string :state
        t.index([:offer_id, :user_id, :message_id], unique: true,
          name: 'offer_user_message')
    end
  end
end
