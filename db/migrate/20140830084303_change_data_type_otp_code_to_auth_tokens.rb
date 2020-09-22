class ChangeDataTypeOtpCodeToAuthTokens < ActiveRecord::Migration[4.2]
  def change
    change_table :auth_tokens do |t|
      t.change :otp_code, :string, limit: 6
    end
  end
end
