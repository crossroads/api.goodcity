class CreateOffers < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.string :language
      t.string :state
      t.string :collection_contact_name
      t.string :collection_contact_phone
      t.string :origin
      t.boolean :stairs
      t.boolean :parking
      t.string :estimated_size
      t.text :notes
      t.integer :created_by_id

      t.timestamps
    end
  end
end
