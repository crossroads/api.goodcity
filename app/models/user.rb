class User < ActiveRecord::Base
  has_paper_trail class_name: "Version"
  include PushUpdates
  include RollbarSpecification
  include UserSearch

  has_one :address, as: :addressable, dependent: :destroy
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :reviewed_offers, foreign_key: :reviewed_by_id, inverse_of: :reviewed_by, class_name: "Offer"
  has_many :messages, class_name: "Message", foreign_key: :sender_id, inverse_of: :sender

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions, source: "offer"

  has_many :unread_subscriptions, -> { where state: "unread" }, class_name: "Subscription"
  has_many :offers_with_unread_messages, class_name: "Offer", through: :unread_subscriptions, source: :offer
  has_many :organisations_users
  has_many :organisations, through: :organisations_users
  has_many :user_roles
  has_many :roles, through: :user_roles

  belongs_to :image, dependent: :destroy
  has_many :moved_packages, class_name: "Package", foreign_key: :stockit_moved_by_id, inverse_of: :stockit_moved_by
  has_many :used_locations, -> { order "packages.stockit_moved_on DESC" }, class_name: "Location", through: :moved_packages, source: :location
  has_many :created_orders, -> { order "id DESC" }, class_name: "Order", foreign_key: :created_by_id

  accepts_nested_attributes_for :address, allow_destroy: true

  validates :mobile, format: {with: Mobile::HONGKONGMOBILEREGEXP}, unless: :request_from_stock_without_mobile?

  validates :mobile, presence: true, unless: :request_from_stock_without_mobile?
  validates :mobile, uniqueness: true, if: 'mobile.present?'

  validates :email, allow_blank: true,
                    format: {with: /\A[^@\s]+@[^@\s]+\Z/}
  validates :email, uniqueness: true, if: 'email.present?'

  validates :email, fake_email: true, :if => lambda { Rails.env.production? }

  validates :title, :inclusion => {:in => TITLE_OPTIONS}, :allow_nil => true

  after_create :generate_auth_token

  scope :reviewers, -> { where(roles: {name: "Reviewer"}).joins(:roles) }
  scope :supervisors, -> { where(roles: {name: "Supervisor"}).joins(:roles) }
  scope :order_fulfilment, -> { where(roles: {name: "Order fulfilment"}).joins(:roles) }
  scope :system, -> { where(roles: {name: "System"}).joins(:roles) }
  scope :staff, -> { where(roles: {name: ["Supervisor", "Reviewer"]}).joins(:roles) }
  scope :except_stockit_user, -> { where.not(first_name: "Stockit", last_name: "User") }

  # used when reviewer is logged into donor app
  attr :treat_user_as_donor

  #added to allow sign_up without mobile number from stock app.
  attr_accessor :request_from_stock, :request_from_browse

  # If user exists, ignore data and just send_verification_pin
  # Otherwise, create new user and send pin
  def self.creation_with_auth(user_params, app_name)
    mobile = user_params["mobile"].presence
    email = user_params["email"].presence
    user = find_user_by_mobile_or_email(mobile, email)
    user ||= new(user_params)
    user.request_from_browse = (app_name == BROWSE_APP)
    user.save if user.changed?
    user.send_verification_pin(app_name, mobile, email) if user.valid?
    user
  end

  def self.find_user_by_mobile_or_email(mobile, email)
    return find_by_mobile(mobile) if mobile
    find_by_email(email) if email
  end

  def send_sms(app_name)
    begin
      TwilioService.new(self).sms_verification_pin(app_name)
    rescue Twilio::REST::RequestError => e
      msg = e.message.try(:split, ".").try(:first)
      self.errors.add(:base, msg)
    end
  end

  def send_pin_email
    begin
      SendgridService.new(self).send_pin_email
    rescue => e
      Rollbar.error(e, error_class: "Sendgrid Error", error_message: "Sendgrid pin email")
    end
  end

  def send_verification_pin(app_name, mobile, email = nil)
    SlackPinService.new(self).send_otp(app_name)
    return send_sms(app_name) if mobile
    send_pin_email if email
  end

  def set_verified_flag(pin_for)
    flag = pin_for.eql?('email') ? :is_email_verified : :is_mobile_verified
    update_column(flag, true) unless send(flag)
  end

  def self.recent_orders_created_for(user_id)
    joins(:created_orders).where(orders: {submitted_by_id: user_id})
      .order("orders.id DESC").limit(5)
  end

  def allowed_login?(app_name)
    if [DONOR_APP, BROWSE_APP].include?(app_name)
      return true
    else
      user_permissions_names.include?(APP_NAME_AND_LOGIN_PERMISSION_MAPPING[app_name])
    end
  end

  def user_permissions_names
    @permissions ||= Permission.names(id)
  end

  def most_recent_token
    auth_tokens.most_recent.first
  end

  def full_name
    [first_name, last_name].reject(&:blank?).map(&:capitalize).join(" ")
  end

  def staff?
    reviewer? || supervisor? || administrator?
  end

  def user_role_names
    @user_role_names ||= roles.pluck(:name)
  end

  def reviewer?
    user_role_names.include?("Reviewer") && @treat_user_as_donor != true
  end

  def charity?
    user_role_names.include?("Charity")
  end

  def supervisor?
    user_role_names.include?("Supervisor") && @treat_user_as_donor != true
  end

  def order_fulfilment?
    user_role_names.include?("Order fulfilment")
  end

  def admin?
    administrator?
  end

  def administrator?
    user_role_names.include?("Administrator") && @treat_user_as_donor != true
  end

  def donor?
    user_role_names.empty? || @treat_user_as_donor == true
  end

  def api_user?
    user_role_names.include?("api-write")
  end

  def online?
    (last_connected && last_disconnected) ?
      (last_connected > last_disconnected) : false
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

  def email_properties
    props = {}
    props["contact_name"] = "#{first_name} #{last_name}"
    org = organisations.first
    if org
      props["contact_organisation_name_en"] = org.name_en
      props["contact_organisation_name_zh_tw"] = org.name_zh_tw
    end
    props
  end

  private

  def request_from_stock_without_mobile?
    request_from_stock && mobile.blank? || request_from_browse && mobile.blank?
  end

  def remove_user_roles(role_ids)
    role_ids_to_remove = roles.pluck(:id) - role_ids
    user_roles.where("role_id IN(?)", role_ids_to_remove).destroy_all
  end

  def generate_auth_token
    auth_tokens.create(user_id: self.id)
  end

  # required by PushUpdates module
  def offer
    nil
  end
end
