class AddWhodunnitVersionIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :versions, :whodunnit
  end
end
