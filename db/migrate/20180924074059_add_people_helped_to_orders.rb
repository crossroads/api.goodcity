class AddPeopleHelpedToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :people_helped, :integer, :default => 0
  end
end
