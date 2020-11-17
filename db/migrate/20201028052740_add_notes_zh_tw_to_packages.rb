class AddNotesZhTwToPackages < ActiveRecord::Migration[5.2]
  def change
    add_column :packages, :notes_zh_tw, :text
  end
end
