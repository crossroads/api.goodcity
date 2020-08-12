class AddFieldsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :receive_email, :boolean, default: false
    add_column :users, :other_phone, :string
  end
end
