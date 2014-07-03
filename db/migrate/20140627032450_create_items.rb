class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.text :donor_description
      t.string :donor_condition
      t.string :state
      t.integer :offer_id
      t.integer :item_type_id
      t.integer :rejection_reason_id
      t.string :rejection_other_reason

      t.timestamps
    end
  end
end
