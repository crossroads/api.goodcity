class AddIndexesToMessage < ActiveRecord::Migration[6.1]
  def change
    add_index :messages, [:messageable_type, :messageable_id], if_not_exists: true
    add_index :messages, [:messageable_id, :messageable_type], if_not_exists: true
  end
end
