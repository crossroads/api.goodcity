class User < ActiveRecord::Base
  has_one :address, as: :addressable, dependent: :destroy
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :reviewed_offers, foreign_key: :reviewed_by_id, inverse_of: :reviewed_by, class_name: 'Offer'
  has_many :messages, foreign_key: :recipient_id, inverse_of: :recipient
  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id, inverse_of: :sender

  has_many :subscribptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscribptions

  belongs_to :permission, inverse_of: :users

  accepts_nested_attributes_for :address, allow_destroy: true

  validates :mobile, presence: true, uniqueness: true

  after_create :generate_auth_token

  scope :find_all_by_otp_secret_key, ->(otp_secret_key) {
    joins(:auth_tokens).where( auth_tokens: { otp_secret_key: otp_secret_key } ) }
  scope :check_for_mobile_uniqueness, ->(entered_mobile) { where("mobile = ?", entered_mobile)}
  scope :get_by_permission, ->(role_id) { where('permission_id in (?)', role_id) }

  def self.creation_with_auth(user_params)
    begin
      transaction do
        user = new(user_params)
        user.send_verification_pin if user.save!
        user
      end
    rescue Twilio::REST::RequestError => e
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
    permission.try(:name) == 'Reviewer'
  end

  def supervisor?
    permission.try(:name) == 'Supervisor'
  end

  def admin?
    administrator?
  end

  def administrator?
    permission.try(:name) == 'Administrator'
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
