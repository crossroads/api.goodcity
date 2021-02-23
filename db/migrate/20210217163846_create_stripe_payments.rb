class CreateStripePayments < ActiveRecord::Migration[5.2]
  def change
    create_table :stripe_payments do |t|
      t.integer :user_id
      t.string  :setup_intent_id
      t.string  :payment_method_id
      t.string  :payment_intent_id
      t.float   :amount
      t.string  :status
      t.string  :receipt_url
      t.string  :source_type
      t.integer :source_id

      t.timestamps
    end
  end
end
