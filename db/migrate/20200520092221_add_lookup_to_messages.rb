class AddLookupToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :lookup, :jsonb, default: '{}'

    add_index :messages, :lookup, using: :gin
  end
end
