class AddAuthorisedByIdToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :authorised_by_id, :integer
  end
end
