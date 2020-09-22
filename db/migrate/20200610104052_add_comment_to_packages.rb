class AddCommentToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :comment, :text
  end
end
