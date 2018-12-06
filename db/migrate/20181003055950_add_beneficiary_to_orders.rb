class AddBeneficiaryToOrders < ActiveRecord::Migration
  def change
    add_reference :orders, :beneficiary, :default => nil
  end
end
