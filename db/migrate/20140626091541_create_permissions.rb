class CreatePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :permissions do |t|
      t.string :name

      t.timestamps
    end
  end
end
