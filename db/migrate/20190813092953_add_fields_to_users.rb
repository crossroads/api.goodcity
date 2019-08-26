class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :receive_email, :boolean, default: false
    add_column :users, :other_phone, :string
  end
end
