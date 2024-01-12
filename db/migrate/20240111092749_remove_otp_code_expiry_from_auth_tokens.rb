class RemoveOtpCodeExpiryFromAuthTokens < ActiveRecord::Migration[6.1]
  def change
    remove_column :auth_tokens, :otp_code_expiry
  end
end
