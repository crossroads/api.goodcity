class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.integer :quantity
      t.references :package_type, index: true, foreign_key: true
      t.references :order, index: true, foreign_key: true
      t.text :description
      t.integer :created_by_id

      t.timestamps null: false
    end
  end
end
