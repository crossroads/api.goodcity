class AddDeletedAtColumn < ActiveRecord::Migration
  def change
    add_column :offers,   :deleted_at, :datetime
    add_column :items,    :deleted_at, :datetime
    add_column :messages, :deleted_at, :datetime
    add_column :images,   :deleted_at, :datetime
    add_column :packages, :deleted_at, :datetime
  end
end
