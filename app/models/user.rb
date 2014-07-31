class User < ActiveRecord::Base
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :messages, foreign_key: :sender_id, inverse_of: :sender
  has_and_belongs_to_many :permissions

  after_create :generate_auth_token

  def self.find_user_based_on_auth(otp_key)
    joins(:auth_tokens).where("auth_tokens.otp_secret_key = ? ", otp_key).first
  end

  def self.check_for_mobile_uniqueness(entered_mobile)
    where("mobile = ?", entered_mobile).first
  end

  def self.creation_with_auth(user_params)
    begin
      transaction do
        user = new(user_params)
        user.send_verification_pin if user.save
        user
      end
    rescue Twilio::REST::RequestError => e
      # e.message.to_s.try(:split,'\;').try(:first)
      e.message.try(:split,'.').try(:first)
    rescue Exception => e
      e.message
    end
  end

  def friendly_token
    auth_tokens.recent_auth_token["otp_secret_key"]
  end

  def token_expiry
    auth_tokens.recent_auth_token["otp_code_expiry"]
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

  def send_verification_pin(drift=30.minutes)
    twilio_sms = TwilioServices.new(self)
    new_auth = update_otp(drift)
    message_data = twilio_sms.sms_verification_pin(
      {otp: new_auth[:otp_code], otp_expires: new_auth[:otp_code_expiry]})
    user_token = new_auth.otp_secret_key
    [user_token, message_data]
  end

  def update_otp(drift)
    user_auth_pin = self.auth_tokens.recent_auth_token
    drift_time = Time.now + drift
    new_otp = user_auth_pin.otp_code(drift_time)
    auth_tokens.recent_auth_token.update_columns(otp_code: new_otp,
      otp_code_expiry: drift_time)
    self.auth_tokens.recent_auth_token
  end

  def generate_auth_token
    auth_tokens.create({user_id:  self.id})
  end
end
