class ChangeRejectionCommentsColumnType < ActiveRecord::Migration[4.2]
  def up
    change_column :items, :rejection_comments, :text
  end

  def down
    change_column :items, :rejection_comments, :string
  end
end
