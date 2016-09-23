class CreatePurposes < ActiveRecord::Migration
  def change
    create_table :purposes do |t|
      t.string :name_en
      t.string :name_zh_tw
      t.timestamps null: false
    end

    create_table :orders_purposes do |t|
      t.belongs_to :order
      t.belongs_to :purpose
    end
  end
end
