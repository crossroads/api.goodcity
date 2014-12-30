class User < ActiveRecord::Base
  include PushUpdates

  has_one :address, as: :addressable, dependent: :destroy
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :reviewed_offers, foreign_key: :reviewed_by_id, inverse_of: :reviewed_by, class_name: 'Offer'
  has_many :messages, class_name: 'Message', foreign_key: :sender_id, inverse_of: :sender

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  belongs_to :permission, inverse_of: :users
  belongs_to :image, dependent: :destroy

  accepts_nested_attributes_for :address, allow_destroy: true

  HongKongMobileRegExp = /\A\+852[569]\d{7}\z/

  validates :mobile, presence: true, uniqueness: true, format: { with: HongKongMobileRegExp }

  after_create :generate_auth_token

  scope :donors,      -> { where( permission_id: nil ) }
  scope :reviewers,   -> { where( permissions: { name: 'Reviewer'   } ).joins(:permission) }
  scope :supervisors, -> { where( permissions: { name: 'Supervisor' } ).joins(:permission) }
  scope :staff,       -> { where( permissions: { name: ['Supervisor', 'Reviewer'] } ).joins(:permission) }

  # If user exists, ignore data and just send_verification_pin
  # Otherwise, create new user and send pin
  def self.creation_with_auth(user_params)
    mobile = user_params['mobile']
    user = nil
    user = self.find_by_mobile(mobile) if mobile.present?
    user ||= new(user_params)
    begin
      transaction do
        user.save
        user.send_verification_pin if user.valid?
      end
    rescue Twilio::REST::RequestError => e
      msg = e.message.try(:split, '.').try(:first)
      user.errors.add(:base, msg)
    end
    user
  end

  def most_recent_token
    auth_tokens.most_recent.first
  end

  def full_name
    [first_name, last_name].reject(&:blank?).map(&:downcase).map(&:capitalize).join(' ')
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

  def donor?
    permission.try(:name) == nil
  end

  def send_verification_pin
    most_recent_token.cycle_otp_auth_key!
    EmailFlowdockService.new(self).send_otp
    TwilioService.new(self).sms_verification_pin
  end

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(user)
    Thread.current[:current_user] = user
  end

  private

  def generate_auth_token
    auth_tokens.create( user_id:  self.id )
  end

  #required by PusherUpdates module
  def donor_user_id
    address.user_id
  end
end
