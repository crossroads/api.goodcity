class AddConnectColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_connected, :datetime
    add_column :users, :last_disconnected, :datetime
  end
end
