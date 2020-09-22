class RemoveOtpCodeFromAuthToken < ActiveRecord::Migration[4.2]
  def change
    remove_column :auth_tokens, :otp_code
  end
end
