class AddStaffNoteToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :staff_note, :string, :default => ''
  end
end
