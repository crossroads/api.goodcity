class AddLookupToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :lookup, :jsonb

    add_index :messages, :lookup, using: :gin
  end
end
