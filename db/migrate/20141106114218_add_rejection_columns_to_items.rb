class AddRejectionColumnsToItems < ActiveRecord::Migration[4.2]
  def change
    rename_column :items, :rejection_other_reason, :reject_reason
    add_column    :items, :rejection_comments, :string
  end
end
