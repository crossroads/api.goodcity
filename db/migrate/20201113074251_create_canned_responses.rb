class CreateCannedResponses < ActiveRecord::Migration[5.2]
  def change
    create_table :canned_responses do |t|
      t.string :name_en
      t.string :name_zh_tw
      t.string :content_en
      t.string :content_zh_tw
      t.string :respondable_type
      t.timestamps
    end
  end
end
