class AddCancellationReasonIdToOrder < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :cancellation_reason_id, :integer
    rename_column :orders, :cancellation_reason, :cancel_reason
  end
end
