class AddNotesToShareables < ActiveRecord::Migration[5.2]
  def change
    add_column :shareables, :notes,       :text
    add_column :shareables, :notes_zh_tw, :text
  end
end
