class AddConnectColumnsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_connected, :datetime
    add_column :users, :last_disconnected, :datetime
  end
end
