class RemoveIsSucessColumnFromBrainTreeTransactions < ActiveRecord::Migration
  def change
    remove_column :braintree_transactions, :is_success
  end
end
