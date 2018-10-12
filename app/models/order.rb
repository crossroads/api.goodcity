class Order < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
  include PushUpdates

  belongs_to :detail, polymorphic: true
  belongs_to :stockit_activity
  belongs_to :country
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
  belongs_to :organisation
  belongs_to :created_by, class_name: 'User'
  belongs_to :processed_by, class_name: 'User'
  belongs_to :cancelled_by, class_name: 'User'
  belongs_to :process_completed_by, class_name: 'User'
  belongs_to :dispatch_started_by, class_name: 'User'
  belongs_to :closed_by, class_name: 'User'
  belongs_to :submitted_by, class_name: 'User'
  belongs_to :stockit_local_order, -> { joins("inner join orders on orders.detail_id = stockit_local_orders.id and (orders.detail_type = 'LocalOrder' or orders.detail_type = 'StockitLocalOrder')") }, foreign_key: 'detail_id'

  has_many :packages
  has_many :goodcity_requests
  has_many :purposes, through: :orders_purposes
  has_many :orders_packages, dependent: :destroy
  has_many :orders_purposes, dependent: :destroy
  has_and_belongs_to_many :cart_packages, class_name: 'Package'
  has_one :order_transport, dependent: :destroy

  after_initialize :set_initial_state
  after_create :update_orders_packages_quantity, if: :draft_goodcity_order?
  before_create :assign_code

  after_destroy :delete_orders_packages

  INACTIVE_STATUS = ['Closed', 'Sent', 'Cancelled']

  INACTIVE_STATES = ['cancelled', 'closed', 'draft'].freeze

  scope :non_draft_orders, -> { where('state NOT IN (?)', 'draft') }

  scope :with_eager_load, -> {
    includes([
      { packages: [:locations, :package_type] }
    ])
  }

  scope :descending, -> { order('id desc') }

  scope :active_orders, -> { where('status NOT IN (?) or orders.state NOT IN (?)', INACTIVE_STATUS, INACTIVE_STATES) }

  scope :my_orders, -> { where("created_by_id = (?)", User.current_user.try(:id)) }

  scope :goodcity_orders, -> { where(detail_type: 'GoodCity') }

  def delete_orders_packages
    if self.orders_packages.exists?
      orders_packages.map(&:destroy)
    end
  end

  def designate_orders_packages
    orders_packages.each do |orders_package|
      orders_package.update_state_to_designated
    end
  end

  def update_orders_packages_quantity
    orders_packages.each do |orders_package|
      orders_package.update_quantity
    end
  end

  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    state :submitted, :processing, :closed, :cancelled, :awaiting_dispatch, :restart_process, :dispatching, :start_dispatching

    event :submit do
      transition draft: :submitted
    end

    event :start_processing do
      transition submitted: :processing
    end

    event :finish_processing do
      transition processing: :awaiting_dispatch
    end

    event :cancel do
      transition all - [:draft, :closed] => :cancelled
    end

    event :close do
      transition dispatching: :closed
    end

    event :reopen do
      transition closed: :dispatching
    end

    event :restart_process do
      transition awaiting_dispatch: :submitted
    end

    event :resubmit do
      transition cancelled: :submitted
    end

    event :dispatch_later do
      transition dispatching: :awaiting_dispatch
    end

    event :start_dispatching do
      transition awaiting_dispatch: :dispatching
    end

    event :redesignate_cancelled_order do
      transition cancelled: :processing
    end

    before_transition on: :submit do |order|
      order.submitted_at = Time.now
      order.submitted_by = User.current_user
      order.add_to_stockit
    end

    before_transition on: :start_processing do |order|
      if order.submitted?
        order.processed_at = Time.now
        order.processed_by = User.current_user
      end
    end

    before_transition on: :redesignate_cancelled_order do |order|
      if order.cancelled?
        order.processed_at = Time.now
        order.processed_by = User.current_user
        order.nullify_columns(:process_completed_at, :process_completed_by_id, :cancelled_at,
          :cancelled_by_id, :dispatch_started_by_id, :dispatch_started_at)
      end
    end

    before_transition on: :start_dispatching do |order|
      if order.awaiting_dispatch?
        order.dispatch_started_at = Time.now
        order.dispatch_started_by = User.current_user
      end
    end

    before_transition on: :finish_processing do |order|
      if order.processing?
        order.process_completed_at = Time.now
        order.process_completed_by = User.current_user
      end
    end

    before_transition on: :cancel do |order|
      order.cancelled_at = Time.now
      order.cancelled_by = User.current_user
      order.orders_packages.each do |orders_package|
        orders_package.cancel
      end
    end

    before_transition on: :close do |order|
      if order.dispatching?
        order.closed_at = Time.now
        order.closed_by = User.current_user
      end
    end

    before_transition on: :dispatch_later do |order|
      if order.dispatching?
        order.nullify_columns(:dispatch_started_at, :dispatch_started_by_id)
      end
    end

    before_transition on: :reopen do |order|
      if order.closed?
        order.dispatch_started_at = Time.now
        order.dispatch_started_by = User.current_user
        order.nullify_columns(:closed_at, :closed_by_id)
      end
    end

    before_transition on: :restart_process do |order|
      if order.awaiting_dispatch?
        order.nullify_columns(:processed_at, :processed_by_id, :process_completed_at, :process_completed_by_id)
      end
    end

    before_transition on: :resubmit do |order|
      if order.cancelled?
        order.nullify_columns(:processed_at, :processed_by_id, :process_completed_at, :process_completed_by_id,
          :cancelled_at, :cancelled_by_id, :dispatch_started_by_id, :dispatch_started_at)
      end
    end

    after_transition on: :submit do |order|
      if order.detail_type == "GoodCity"
        order.designate_orders_packages
        order.send_new_order_notificationen
        order.send_new_order_confirmed_sms_to_charity
        order.send_order_placed_sms_to_order_fulfilment_users
      end
    end
  end

  def send_new_order_notificationen
    PushService.new.send_notification Channel.goodcity_order_channel, STOCK_APP, {
      category:   'new_order',
      message:    I18n.t("notification.new_order", organisation_name_en:
        organisation.try(:name_en), organisation_name_zh_tw: organisation.try(:name_zh_tw),
        contact_name: created_by.full_name),
      order_id:   id,
      author_id:  created_by_id
    }
  end

  def send_new_order_confirmed_sms_to_charity
    TwilioService.new(submitted_by).order_confirmed_sms_to_charity(self)
  end

  def send_order_placed_sms_to_order_fulfilment_users
    User.order_fulfilment.each do |user|
      TwilioService.new(user).order_submitted_sms_to_order_fulfilment_users(self)
    end
  end

  def nullify_columns(*columns)
    columns.map { |column| send("#{column}=", nil) }
  end

  def add_to_stockit
    response = Stockit::DesignationSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (designation_id = response["designation_id"]).present?
      self.stockit_id = designation_id
    end
  end

  def self.search(search_text, to_designate_item)
    fetch_orders(to_designate_item)
      .where("code ILIKE :query OR
      description ILIKE :query OR
      organisations.name_en ILIKE :query OR
      organisations.name_zh_tw ILIKE :query OR
      CONCAT(users.first_name, ' ', users.last_name) ILIKE :query OR
      stockit_organisations.name ILIKE :query OR
      stockit_local_orders.client_name ILIKE :query OR
      stockit_contacts.first_name ILIKE :query OR stockit_contacts.last_name ILIKE :query OR
      stockit_contacts.mobile_phone_number LIKE :query OR
      stockit_contacts.phone_number LIKE :query", query: "%#{search_text}%")
  end

  def self.fetch_orders(to_designate_item)
    if to_designate_item
      join_order_associations.active_orders
    else
      join_order_associations.non_draft_orders
    end
  end

  def self.join_order_associations
    joins("LEFT OUTER JOIN stockit_local_orders ON orders.detail_id = stockit_local_orders.id and orders.detail_type = 'LocalOrder'
    LEFT OUTER JOIN users ON orders.submitted_by_id = users.id or orders.created_by_id = users.id
    LEFT OUTER JOIN stockit_contacts ON orders.stockit_contact_id = stockit_contacts.id
    LEFT OUTER JOIN stockit_organisations ON orders.stockit_organisation_id = stockit_organisations.id
    LEFT OUTER JOIN organisations ON orders.organisation_id = organisations.id")
  end

  def self.recently_used(user_id)
    active_orders
    .select("DISTINCT ON (orders.id) orders.id AS key,  versions.created_at AS recently_used_at").
    joins("INNER JOIN versions ON ((object_changes -> 'order_id' ->> 1) = CAST(orders.id AS TEXT))").
    joins("INNER JOIN packages ON (packages.id = versions.item_id AND versions.item_type = 'Package')").
    where(" versions.event = 'update' AND
      (object_changes ->> 'order_id') IS NOT NULL AND
      CAST(whodunnit AS integer) = ? AND
      versions.created_at >= ? ", user_id, 15.days.ago).
    order("key, recently_used_at DESC")
  end

  def self.generate_gc_code
    record = where(detail_type: "GoodCity").order("id desc").first
    "GC-" + gc_code(record).to_s.rjust(5, "0")
  end

  def self.gc_code(record)
    record ? record.code.gsub(/\D/, '').to_i + 1 : 1
  end

  def goodcity_order?
    detail_type == "GoodCity"
  end

  def draft_goodcity_order?
    state == "draft" && goodcity_order?
  end

  def delete_if_no_orders_packages
    self.destroy if draft_goodcity_order? and !orders_packages.exists?
  end

  private

  def assign_code
    self.code = Order.generate_gc_code if goodcity_order?
  end

  #to satisfy push_updates
  def order
    self
  end

  #to satisfy push_updates
  def offer
    nil
  end
end
