class RenameColumnReviewedByIdToUpdatedById < ActiveRecord::Migration
  def change
    rename_column :orders_packages, :reviewed_by_id, :updated_by_id
  end
end
