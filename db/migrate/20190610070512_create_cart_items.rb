class CreateCartItems < ActiveRecord::Migration
  def change
    create_table :cart_items do |t|
      t.references :user, index: true
      t.references :package, index: true
      t.boolean :is_available
    end

    add_index :cart_items, [:user_id, :package_id], :unique => true
    add_index :cart_items, [:package_id, :user_id], :unique => true
  end
end
