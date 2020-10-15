class AddBeneficiaryToOrders < ActiveRecord::Migration[4.2]
  def change
    add_reference :orders, :beneficiary, :default => nil
  end
end
