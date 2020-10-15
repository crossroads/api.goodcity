class RenameColumnReviewedByIdToUpdatedById < ActiveRecord::Migration[4.2]
  def change
    rename_column :orders_packages, :reviewed_by_id, :updated_by_id
  end
end
