class AuthToken < ActiveRecord::Base
  belongs_to :user
  has_one_time_password length: 4

  scope :most_recent, -> { order('id desc').limit(1) }

  before_validation(on: :create) { self.otp_auth_key = new_otp_auth_key }

  validates :otp_auth_key, presence: true

  # Generate the otp_code as normal but set default drift_time (can be overridden)
  # We store otp_code_expiry purely so we can include it on our SMS messages
  # Cycle the otp_auth_key so it it not always the same.
  def otp_code(options={})
    options.reverse_merge!( time: drift_time )
    update_columns( otp_code_expiry: drift_time )
    super(options)
  end

  def cycle_otp_auth_key!
    update_columns( otp_auth_key: new_otp_auth_key )
  end

  def new_otp_auth_key
    SecureRandom.base64
  end

  private

  # Number of seconds the OTP code is valid for
  def otp_code_validity
    Rails.application.secrets.token['otp_code_validity']
  end

  def drift_time
    Time.now + otp_code_validity
  end

end
