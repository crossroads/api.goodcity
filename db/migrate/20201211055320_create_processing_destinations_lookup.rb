class CreateProcessingDestinationsLookup < ActiveRecord::Migration[5.2]
  def change
    create_table :processing_destinations_lookups do |t|
      t.string :name
      t.timestamps
    end
  end
end
