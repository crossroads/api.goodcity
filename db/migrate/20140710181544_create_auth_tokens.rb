class CreateAuthTokens < ActiveRecord::Migration
  def change
    create_table :auth_tokens do |t|
      t.integer :otp_code
      t.datetime :otp_code_expiry
      t.string :otp_secret_key
      t.integer :user_id

      t.timestamps
    end
  end
end
