class AddCommentToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :comment, :text
  end
end
