class User < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
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

  validates :mobile, presence: true, uniqueness: true, format: { with: Mobile::HongKongMobileRegExp }

  after_create :generate_auth_token

  scope :donors,      -> { where( permission_id: nil ) }
  scope :reviewers,   -> { where( permissions: { name: 'Reviewer'   } ).joins(:permission) }
  scope :supervisors, -> { where( permissions: { name: 'Supervisor' } ).joins(:permission) }
  scope :system,      -> { where( permissions: { name: 'System' } ).joins(:permission) }
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

  def staff?
    reviewer? || supervisor? || administrator?
  end

  def reviewer?
    permission.try(:name) == 'Reviewer'
  end

  def supervisor?
    permission.try(:name) == 'Supervisor'
  end

  def system?
    permission.try(:name) == 'System'
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

  def online?
    (last_connected && last_disconnected) ?
      (last_connected > last_disconnected) : false
  end

  def send_verification_pin
    most_recent_token.cycle_otp_auth_key!
    EmailFlowdockService.new(self).send_otp
    TwilioService.new(self).sms_verification_pin
  end

  def channels(app)
    channels = Channel.private(self)
    if app == ADMIN_APP
      channels += Channel.reviewer if reviewer?
      channels += Channel.supervisor if supervisor?
    end
    channels
  end

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(user)
    Thread.current[:current_user] = user
  end

  def self.system_user
    User.system.order(:id).first
  end

  def system_user?
    User.system.pluck(:id).include?(self.id)
  end

  def recent_active_offer_id
    Version.for_offers.by_user(id).last.try(:item_id_or_related_id)
  end

  private

  def generate_auth_token
    auth_tokens.create( user_id:  self.id )
  end

  # required by PushUpdates module
  def offer
    nil
  end
end
