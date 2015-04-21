class AddUuidToGgvOrder < ActiveRecord::Migration
  def change
    add_column :gogovan_orders, :ggv_uuid, :string
    add_index :gogovan_orders, :ggv_uuid, unique: true
  end
end
