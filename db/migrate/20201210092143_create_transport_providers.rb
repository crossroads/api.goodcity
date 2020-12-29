class CreateTransportProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :transport_providers do |t|
      t.string :name
      t.string :logo
      t.text   :description
      t.jsonb  :metadata,  default: '{}'

      t.timestamps
    end
  end
end
