class AddVisibleToOrderToCancellationReason < ActiveRecord::Migration[4.2]
  def change
    add_column :cancellation_reasons, :visible_to_order, :boolean, default: false
    rename_column :cancellation_reasons, :visible_to_admin, :visible_to_offer
  end
end
