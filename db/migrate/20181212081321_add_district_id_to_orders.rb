class AddDistrictIdToOrders < ActiveRecord::Migration
  def change
    add_reference :orders, :district, index: true, foreign_key: true
  end
end
