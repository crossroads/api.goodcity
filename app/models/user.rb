class User < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
  include PushUpdates
  include RollbarSpecification

  has_one :address, as: :addressable, dependent: :destroy
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :reviewed_offers, foreign_key: :reviewed_by_id, inverse_of: :reviewed_by, class_name: 'Offer'
  has_many :messages, class_name: 'Message', foreign_key: :sender_id, inverse_of: :sender

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  has_many :unread_subscriptions, -> { where state: 'unread' }, class_name: "Subscription"
  has_many :offers_with_unread_messages, class_name: "Offer", through: :unread_subscriptions, source: :offer
  has_many :braintree_transactions, class_name: "BraintreeTransaction", foreign_key: :customer_id
  has_many :organisations_users
  has_many :organisations, through: :organisations_users
  has_many :user_roles
  has_many :roles, through: :user_roles

  belongs_to :image, dependent: :destroy
  has_many :moved_packages, class_name: "Package", foreign_key: :stockit_moved_by_id, inverse_of: :stockit_moved_by
  has_many :used_locations, -> { order 'packages.stockit_moved_on DESC' }, class_name: "Location", through: :moved_packages, source: :location

  accepts_nested_attributes_for :address, allow_destroy: true

  validates :mobile, presence: true, uniqueness: true, format: { with: Mobile::HONGKONGMOBILEREGEXP }

  validates :email, uniqueness: true, allow_nil: true,
    format: { with: /\A[^@\s]+@[^@\s]+\Z/ }

  after_create :generate_auth_token

  scope :donors,      -> { where(permission_id: nil) }
  scope :reviewers,   -> { where(roles: { name: 'Reviewer'   }).joins(:roles) }
  scope :supervisors, -> { where(roles: { name: 'Supervisor' }).joins(:roles) }
  scope :system,      -> { where(roles: { name: 'System' }).joins(:roles) }
  scope :staff,       -> { where(roles: { name: ['Supervisor', 'Reviewer'] }).joins(:roles) }
  scope :except_stockit_user, -> { where.not(first_name: "Stockit", last_name: "User") }

  # used when reviewer is logged into donor app
  attr :treat_user_as_donor

  # If user exists, ignore data and just send_verification_pin
  # Otherwise, create new user and send pin
  def self.creation_with_auth(user_params)
    mobile = user_params['mobile']
    user = find_by_mobile(mobile) if mobile.present?
    user ||= new(user_params)
    begin
      user.save if user.changed?
      user.send_verification_pin if user.valid?
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
    [first_name, last_name].reject(&:blank?).map(&:capitalize).join(' ')
  end

  def staff?
    reviewer? || supervisor? || administrator?
  end

  def user_role_names
    roles.pluck(:name)
  end

  def reviewer?
    user_role_names.include?('Reviewer') && @treat_user_as_donor != true
  end

  def charity?
    user_role_names.include?('Charity')
  end

  def supervisor?
    user_role_names.include?('Supervisor') && @treat_user_as_donor != true
  end

  def admin?
    administrator?
  end

  def administrator?
    user_role_names.include?('Administrator') && @treat_user_as_donor != true
  end

  def donor?
    !roles.exists? || @treat_user_as_donor == true
  end

  def api_user?
    user_role_names.include?('api-write')
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

  def channels
    channels = Channel.private(self)
    channels += Channel.reviewer if reviewer?
    channels += Channel.supervisor if supervisor?
    channels
  end

  def self.current_user
    RequestStore.store[:current_user]
  end

  def self.current_user=(user)
    RequestStore.store[:current_user] = user
  end

  def self.system_user
    User.system.order(:id).first
  end

  def system_user?
    User.system.pluck(:id).include?(self.id)
  end

  def self.stockit_user
    find_by(first_name: "Stockit", last_name: "User")
  end

  def recent_active_offer_id
    Version.for_offers.by_user(id).last.try(:related_id_or_item_id)
  end

  def create_or_remove_user_roles(role_ids)
    role_ids = role_ids || []
    remove_user_roles(role_ids)
    role_ids.each do |role_id|
      user_roles.where(role_id: role_id).first_or_create
    end
  end

  private

  def remove_user_roles(role_ids)
    role_ids_to_remove = roles.pluck(:id) - role_ids
    user_roles.where("role_id IN(?)", role_ids_to_remove).destroy_all
  end

  def generate_auth_token
    auth_tokens.create( user_id: self.id )
  end

  # required by PushUpdates module
  def offer
    nil
  end
end


