class AddLastOtpAtToAuthTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :auth_tokens, :last_otp_at, :integer
  end
end
