class RemoveOtpCodeFromAuthToken < ActiveRecord::Migration
  def change
    remove_column :auth_tokens, :otp_code
  end
end
