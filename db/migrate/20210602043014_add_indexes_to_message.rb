class AddIndexesToMessage < ActiveRecord::Migration[6.1]
  def change
    # add_index :messages, [:messageable_type, :messageable_id]
    # add_index :messages, [:messageable_id, :messageable_type]
  end
end
