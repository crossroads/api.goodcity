class AddCostToCrossroadsTransports < ActiveRecord::Migration[4.2]
  def change
    add_column :crossroads_transports, :cost, :integer
    add_column :crossroads_transports, :truck_size, :float
  end
end
