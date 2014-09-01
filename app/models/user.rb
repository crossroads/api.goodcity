class User < ActiveRecord::Base
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :messages, foreign_key: :sender_id, inverse_of: :sender
  has_and_belongs_to_many :permissions
  belongs_to :district

  validates :mobile, presence: true, uniqueness: true

  after_create :generate_auth_token

  scope :find_all_by_otp_secret_key, ->(otp_secret_key) {
    joins(:auth_tokens).where( auth_tokens: { otp_secret_key: otp_secret_key } ) }
  scope :check_for_mobile_uniqueness, ->(entered_mobile) { where("mobile = ?", entered_mobile)}

  def self.creation_with_auth(user_params)
    begin
      transaction do
        user = new(user_params)
        user.send_verification_pin if user.save!
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
    auth_tokens.recent_auth_token["otp_secret_key"] unless auth_tokens.blank?
  end

  def full_name
    [first_name, last_name]
      .reject(&:blank?)
      .map(&:downcase)
      .map(&:capitalize)
      .join(' ')
  end

  def token_expiry
    auth_tokens.recent_auth_token["otp_code_expiry"] unless auth_tokens.blank?
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
    new_otp = user_auth_pin.otp_code({drift: drift_time, padding: true})
    auth_tokens.recent_auth_token.update_columns(otp_code: new_otp,
      otp_code_expiry: drift_time)
    self.auth_tokens.recent_auth_token
  end

  def generate_auth_token
    auth_tokens.create({user_id:  self.id})
  end
end
