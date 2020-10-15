class AddDistrictToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :district_id, :integer
  end
end
