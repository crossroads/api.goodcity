class DropBraintreeTransactionTable < ActiveRecord::Migration
  def change
    drop_table :braintree_transactions
  end
end
