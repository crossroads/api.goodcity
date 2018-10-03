class AddBeneficiaryToOrders < ActiveRecord::Migration
  def change
    add_reference :orders, :beneficiary
  end
end
