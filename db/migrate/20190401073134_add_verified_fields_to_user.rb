class AddVerifiedFieldsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_mobile_verified, :boolean, default: false
    add_column :users, :is_email_verified, :boolean, default: false
  end
end
