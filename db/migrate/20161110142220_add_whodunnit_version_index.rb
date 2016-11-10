class AddWhodunnitVersionIndex < ActiveRecord::Migration
  def change
    add_index :versions, :whodunnit
  end
end
