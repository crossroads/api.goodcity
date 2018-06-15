class RenameDispatchStartedBytoDispatchStartedById < ActiveRecord::Migration
  def change
    rename_column :orders, :dispatch_started_by, :dispatch_started_by_id
  end
end
