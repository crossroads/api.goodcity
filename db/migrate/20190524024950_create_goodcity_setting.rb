class CreateGoodcitySetting < ActiveRecord::Migration
  def change
    create_table :goodcity_settings do |t|
      t.string :key, index: true, unique: true
      t.string :value
      t.string :description
    end
  end
end
