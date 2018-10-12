class AddPeopleHelpedToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :people_helped, :integer, :default => 0
  end
end
