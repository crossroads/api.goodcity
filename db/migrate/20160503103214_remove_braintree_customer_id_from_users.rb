class RemoveBraintreeCustomerIdFromUsers < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :braintree_customer_id
  end

  def down
    add_column :users, :braintree_customer_id, :integer
  end
end
