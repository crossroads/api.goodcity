class AddUniquenMobileConstrainToUsers < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :mobile, unique: true
  end
end
