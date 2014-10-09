class AuthToken < ActiveRecord::Base
  belongs_to :user
  has_one_time_password length: 4

  scope :most_recent, -> { order('id desc').limit(1) }

  # Generate the otp_code as normal but set default drift_time (can be overridden)
  # We store otp_code_expiry purely so we can include it on our SMS messages
  def otp_code(options={})
    options.reverse_merge!( time: drift_time )
    update_columns( otp_code_expiry: drift_time )
    super(options)
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
