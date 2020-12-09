class CreateShareables < ActiveRecord::Migration[5.2]
  def change
    create_table :shareables do |t|
      t.string    :resource_type,  null: false, index: true, null: false
      t.integer   :resource_id,    null: false
      t.string    :public_uid,      null: false
      t.boolean   :allow_listing,   null: false, default: false
      t.datetime  :expires_at,      null: true,  index: true, default: nil
      t.integer   :created_by_id,   index: true

      t.timestamps
    end

    add_index :shareables, [:resource_type, :resource_id], unique: true
    add_index :shareables, [:resource_id, :resource_type], unique: true
  end
end
