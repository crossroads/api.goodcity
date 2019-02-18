class AddStaffNoteToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :staff_note, :string, :default => ''
  end
end
