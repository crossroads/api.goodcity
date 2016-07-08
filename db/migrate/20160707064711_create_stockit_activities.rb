class CreateStockitActivities < ActiveRecord::Migration
  def change
    create_table :stockit_activities do |t|
      t.string :name
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
