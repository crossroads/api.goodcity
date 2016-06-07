class AddIsSuccessToBraintreeTransactions < ActiveRecord::Migration
  def up
    add_column :braintree_transactions, :is_success, :boolean

    BraintreeTransaction.reset_column_information
    BraintreeTransaction.update_all(is_success: true)
  end

  def down
    remove_column :braintree_transactions, :is_success
  end
end
