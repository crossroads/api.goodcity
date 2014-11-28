class AddDeletedAtColumnToTables < ActiveRecord::Migration
  def change
    add_column :addresses,      :deleted_at, :datetime
    add_column :contacts,       :deleted_at, :datetime
    add_column :deliveries,     :deleted_at, :datetime
    add_column :gogovan_orders, :deleted_at, :datetime
  end
end
