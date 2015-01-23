class AddCostToCrossroadsTransports < ActiveRecord::Migration
  def change
    add_column :crossroads_transports, :cost, :integer
    add_column :crossroads_transports, :truck_size, :float
  end
end
