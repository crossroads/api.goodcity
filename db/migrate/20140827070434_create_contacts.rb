class CreateContacts < ActiveRecord::Migration[4.2]
  def change
    create_table :contacts do |t|
      t.string  :name
      t.string  :mobile

      t.timestamps
    end
  end
end
