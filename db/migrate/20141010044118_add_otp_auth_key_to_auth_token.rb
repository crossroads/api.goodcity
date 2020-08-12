class AddOtpAuthKeyToAuthToken < ActiveRecord::Migration[4.2]
  def change
    add_column :auth_tokens, :otp_auth_key, :string, limit: 30
  end
end
