class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.integer :crm_id
      t.integer :created_by_id

      t.timestamps null: false
    end
  end
end
