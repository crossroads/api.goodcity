class CreateGoodcitySetting < ActiveRecord::Migration
  def change
    create_table :goodcity_settings do |t|
      t.string :key, index: true, unique: true, foreign_key: true
      t.string :value
      t.string :desc
    end
  end
end
