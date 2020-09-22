class RenameDispatchStartedBytoDispatchStartedById < ActiveRecord::Migration[4.2]
  def change
    rename_column :orders, :dispatch_started_by, :dispatch_started_by_id
  end
end
