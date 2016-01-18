class CreateCancellationReasons < ActiveRecord::Migration
  def change
    create_table :cancellation_reasons do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps null: false
    end
  end
end
