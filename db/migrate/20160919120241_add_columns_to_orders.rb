class AddColumnsToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :created_by_id, :integer
    add_column :orders, :processed_by_id, :integer
    add_column :orders, :organisation_id, :integer
    add_column :orders, :state, :string
  end
end
