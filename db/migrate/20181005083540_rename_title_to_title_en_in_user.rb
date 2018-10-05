class RenameTitleToTitleEnInUser < ActiveRecord::Migration
  def change
    rename_column :users, :title, :title_en
  end
end
