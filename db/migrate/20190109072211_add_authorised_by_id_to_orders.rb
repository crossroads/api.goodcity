class AddAuthorisedByIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :authorised_by_id, :integer
  end
end
