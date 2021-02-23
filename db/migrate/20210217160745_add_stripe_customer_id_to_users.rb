class AddStripeCustomerIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :stripe_customer_id, :string, default: nil
  end
end
