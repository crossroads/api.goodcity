class CreateAccessPasses < ActiveRecord::Migration[6.1]
  def change
    create_table :access_passes do |t|
      t.datetime :access_expires_at
      t.datetime :generated_at
      t.integer :generated_by_id
      t.integer :access_key
      t.references :printer, foreign_key: true

      t.timestamps
    end

    add_index :access_passes, :access_key, unique: true
  end
end
