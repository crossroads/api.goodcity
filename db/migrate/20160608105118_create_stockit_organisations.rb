class CreateStockitOrganisations < ActiveRecord::Migration
  def change
    create_table :stockit_organisations do |t|
      t.string :name
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
