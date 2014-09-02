class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string  :flat
      t.string  :building
      t.string  :street
      t.integer :district_id
      t.integer :addressable_id
      t.string  :addressable_type
      t.string  :address_type

      t.timestamps
    end
  end
end
