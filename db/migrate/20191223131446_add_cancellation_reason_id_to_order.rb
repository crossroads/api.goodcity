class AddCancellationReasonIdToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :cancellation_reason_id, :integer
    rename_column :orders, :cancellation_reason, :cancel_reason
  end
end
