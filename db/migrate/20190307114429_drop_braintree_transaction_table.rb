class DropBraintreeTransactionTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :braintree_transactions
  end
end
