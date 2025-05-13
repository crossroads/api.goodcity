class AddSendPinViaEmailToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :send_pin_via_email, :boolean, default: false, null: false
  end
end
