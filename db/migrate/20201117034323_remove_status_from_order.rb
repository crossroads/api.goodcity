class RemoveStatusFromOrder < ActiveRecord::Migration[5.2]
  def change
    remove_column :orders, :status
  end
end
