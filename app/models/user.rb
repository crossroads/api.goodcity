class User < ActiveRecord::Base
  has_many :auth_tokens
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :messages, foreign_key: :sender_id, inverse_of: :sender
  has_and_belongs_to_many :permissions
  accepts_nested_attributes_for :auth_tokens
  after_create :generate_auth_record

  def friendly_token
    auth_tokens.first.otp_secret_key
  end

  def token_expiry
    auth_tokens.first.otp_code_expiry
  end

  def reviewer?
    permissions.pluck(:name).include?('Reviewer')
  end

  def supervisor?
    permissions.pluck(:name).include?('Supervisor')
  end

  def admin?
    administrator?
  end

  def administrator?
    permissions.pluck(:name).include?('Administrator')
  end

  def authenticate(mobile)
    send_verification_pin if mobile.eql?(self.mobile)
  end

  def send_verification_pin
    twilio_sms = TwilioServices.new(self)
    user_auth_pin = self.auth_tokens.first
    new_otp = user_auth_pin.otp_code(Time.now + 30.minutes)
    new_otp_expiry = Time.now + 30.minutes
    self.auth_tokens.first.update_columns(otp_code: new_otp, otp_code_expiry: new_otp_expiry)
    twilio_sms.sms_verification_pin({otp: new_otp, otp_expires: new_otp_expiry})
    user_token = user_auth_pin.otp_secret_key
  end

  def generate_auth_record
    auth_tokens.create({user_id:  self.id})
  end

end
