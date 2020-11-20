class User < ApplicationRecord
  has_paper_trail versions: { class_name: "Version" }
  include PushUpdates

  include ManageUserRoles
  include FuzzySearch

  # --------------------
  # Configuration
  # --------------------

  configure_search(
    props: [
      :first_name,
      :last_name,
      :email,
      :mobile
    ],
    default_tolerance: 0.8
  )

  # --------------------
  # Relationships
  # --------------------

  has_one :address, as: :addressable, dependent: :destroy
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :reviewed_offers, foreign_key: :reviewed_by_id, inverse_of: :reviewed_by, class_name: "Offer"
  has_many :messages, class_name: "Message", foreign_key: :sender_id, inverse_of: :sender

  has_many :requested_packages, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions, source: "offer"

  has_many :unread_subscriptions, -> { where state: "unread" }, class_name: "Subscription"
  has_many :offers_with_unread_messages, class_name: 'Offer', through: :unread_subscriptions, source: :subscribable, source_type: 'Offer'

  has_many :organisations_users
  has_many :organisations, through: :organisations_users
  has_many :active_organisations_users, -> { where(status: OrganisationsUser::ACTIVE_STATUS) }, class_name: "OrganisationsUser"
  has_many :active_organisations, class_name: "Organisation", through: :active_organisations_users, source: "organisation"
  has_many :printers_users
  has_many :printers, through: :printers_users

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :active_user_roles, -> { where("expires_at IS NULL OR expires_at >= ?", Time.now.in_time_zone) },
            class_name: "UserRole"
  has_many :active_roles, class_name: "Role", through: :active_user_roles, source: "role"

  belongs_to :image, dependent: :destroy
  has_many :moved_packages, class_name: "Package", foreign_key: :stockit_moved_by_id, inverse_of: :stockit_moved_by
  has_many :used_locations, -> { order "packages.stockit_moved_on DESC" }, class_name: "Location", through: :moved_packages, source: :location
  has_many :created_orders, -> { order "id DESC" }, class_name: "Order", foreign_key: :created_by_id

  accepts_nested_attributes_for :address, allow_destroy: true

  # --------------------
  # Validations
  # --------------------

  validates :mobile, format: {with: Mobile::HONGKONGMOBILEREGEXP}, if: lambda { mobile.present? }
  validates :mobile, presence: true, if: lambda { email.blank? && !disabled }
  validates :mobile, uniqueness: true, if: lambda { mobile.present? }

  validates :email, allow_blank: true,
                    format: {with: /\A[^@\s]+@[^@\s]+\Z/}
  validates :email, uniqueness: true, if: lambda { email.present? }
  validates :email, fake_email: true, :if => lambda { Rails.env.production? }

  validates :title, :inclusion => {:in => TITLE_OPTIONS}, :allow_nil => true
  validates :preferred_language,
            inclusion: { in: I18n.available_locales.map { |lang| lang.to_s.downcase } },
            allow_nil: true

  # --------------------
  # Lifecycle hooks
  # --------------------

  after_create :refresh_auth_token!

  before_validation :downcase_email

  before_save :reset_email_verification_flag, if: :email_changed?
  before_save :reset_mobile_verification_flag, if: :mobile_changed?

  before_destroy :delete_auth_tokens

  # --------------------
  # Scopes
  # --------------------

  scope :reviewers, -> { where(roles: {name: "Reviewer"}).joins(:active_roles) }
  scope :supervisors, -> { where(roles: {name: "Supervisor"}).joins(:active_roles) }
  scope :stock_fulfilments, -> { where(roles: {name: "Stock fulfilment"}).joins(:active_roles) }
  scope :stock_administrators, -> { where(roles: { name: 'Stock administrator' }).joins(:active_roles) }
  scope :order_fulfilments, -> { where(roles: {name: "Order fulfilment"}).joins(:active_roles) }
  scope :order_administrators, -> { where(roles: { name: 'Order administrator' }).joins(:active_roles) }
  scope :system, -> { where(roles: {name: "System"}).joins(:active_roles) }

  scope :staff, -> { where(roles: {name: ["Supervisor", "Reviewer"]}).joins(:active_roles) }
  scope :except_stockit_user, -> { where.not(first_name: "Stockit", last_name: "User") }
  scope :active, -> { where(disabled: false) }
  scope :exclude_user, ->(id) { where.not(id: id) }
  scope :with_roles, ->(role_names) { where(roles: { name: role_names }).joins(:active_roles) }
  scope :with_organisation_status, ->(status_list) { joins(:organisations_users).where(organisations_users: { status: status_list }) }

  # --------------------
  # Methods
  # --------------------

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
    if mobile.present?
      return find_by_mobile(mobile)
    elsif email.present?
      find_by('LOWER(users.email) = ?', email.downcase)
    else
      nil
    end
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
    return unless pin_for.present?
    update_column(:is_email_verified, true)   if pin_for.to_sym.eql?(:email)
    update_column(:is_mobile_verified, true)  if pin_for.to_sym.eql?(:mobile)
  end

  def self.recent_orders_created_for(user_id)
    joins(:created_orders).where(orders: {submitted_by_id: user_id})
      .order("orders.id DESC").limit(5)
  end

  def self.filter_users(opts)
    res = search(opts['searchText']) if opts['searchText'].present?
    res = res.with_organisation_status(opts['organisation_status'].split(',')) if opts['organisation_status'].present?
    res = res.with_roles(opts['role_name']) if opts['role_name'].present?
    res
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
    reviewer? || supervisor?
  end

  def user_role_names
    @user_role_names ||= active_roles.pluck(:name)
  end

  def top_role
    roles.order('level DESC').first
  end

  def reviewer?
    user_role_names.include?("Reviewer") && @treat_user_as_donor != true
  end

  def supervisor?
    user_role_names.include?("Supervisor") && @treat_user_as_donor != true
  end

  def order_fulfilment?
    user_role_names.include?('Order fulfilment')
  end

  def stock_fulfilment?
    user_role_names.include?('Stock fulfilment')
  end

  def stock_administrator?
    user_role_names.include?('Stock administrator')
  end

  def has_permission?(permssion)
    user_permissions_names.include?(permssion)
  end

  def can_disable_user?(id = nil)
    has_permission?("can_disable_user") && User.current_user.id != id&.to_i
  end

  def can_manage_private_messages?
    (user_permissions_names &
    ["can_manage_offer_messages", "can_manage_order_messages", "can_manage_package_messages"]).any?
  end

  def downcase_email
    email.downcase! if email.present?
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

  def self.current_device_id
    RequestStore.store[:current_device_id]
  end

  def self.current_device_id=(device_id)
    RequestStore.store[:current_device_id] = device_id
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

  def delete_auth_tokens
    AuthToken.where(user: self).destroy_all
  end

  def refresh_auth_token!
    # Create new token
    token = auth_tokens.create!(user_id: self.id)

    # Delete old ones
    AuthToken
      .where(user: self)
      .where.not(id: token.id)
      .destroy_all

    token
  end

  private

  # required by PushUpdates module
  def offer
    nil
  end

  def reset_email_verification_flag
    self.is_email_verified = false
    true
  end

  def reset_mobile_verification_flag
    self.is_mobile_verified = false
    true
  end
end
