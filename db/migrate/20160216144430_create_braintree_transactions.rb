class CreateBraintreeTransactions < ActiveRecord::Migration[4.2]
  def change
    create_table :braintree_transactions do |t|
      t.string :transaction_id
      t.integer :customer_id
      t.decimal :amount
      t.string :status

      t.timestamps null: false
    end
  end
end
