class AddDistrictToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :district_id, :integer
  end
end
