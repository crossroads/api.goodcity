class CreateStockitDesignations < ActiveRecord::Migration
  def change
    create_table :stockit_designations do |t|
      t.string :status
      t.string :code
      t.string :detail_type
      t.integer :detail_id
      t.integer :stockit_contact_id
      t.integer :stockit_organisation_id
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
