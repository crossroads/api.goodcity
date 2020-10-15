class CreateMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :messages do |t|
      t.text :body
      t.string :recipient_type
      t.integer :recipient_id
      t.integer :sender_id
      t.boolean :private

      t.timestamps
    end
  end
end
