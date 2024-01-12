class AuthToken < ApplicationRecord
  belongs_to :user
  has_one_time_password column_name: :otp_secret_key, length: 4

  scope :most_recent, -> { order('id desc').limit(1) }

  before_validation(on: :create) { self.otp_auth_key = new_otp_auth_key }

  validates :otp_auth_key, presence: true

  # otp_auth_key is sent to the requesting client via HTTP response when the TOTP is sent via SMS
  # When the client authenticates with TOTP, they also send back the otp_auth_key in order to facilitate
  # auth_token retrieval to compare the code. Each code is unique to the user.
  def new_otp_auth_key
    SecureRandom.base64
  end

end
