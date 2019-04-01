class Order < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
  include PushUpdates
  include OrderFiltering

  belongs_to :detail, polymorphic: true, dependent: :destroy
  belongs_to :stockit_activity
  belongs_to :country
  belongs_to :district
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
  belongs_to :organisation
  belongs_to :beneficiary
  belongs_to :address
  belongs_to :booking_type
  belongs_to :created_by, class_name: 'User'
  belongs_to :processed_by, class_name: 'User'
  belongs_to :cancelled_by, class_name: 'User'
  belongs_to :process_completed_by, class_name: 'User'
  belongs_to :dispatch_started_by, class_name: 'User'
  belongs_to :closed_by, class_name: 'User'
  belongs_to :submitted_by, class_name: 'User'
  belongs_to :stockit_local_order, -> { joins("inner join orders on orders.detail_id = stockit_local_orders.id and (orders.detail_type = 'LocalOrder' or orders.detail_type = 'StockitLocalOrder')") }, foreign_key: 'detail_id'

  has_many :packages
  has_many :goodcity_requests, dependent: :destroy
  has_many :purposes, through: :orders_purposes
  has_many :orders_packages, dependent: :destroy
  has_many :orders_purposes, dependent: :destroy
  has_many :messages, dependent: :destroy, inverse_of: :order
  has_many :subscriptions, dependent: :destroy, inverse_of: :order
  has_and_belongs_to_many :cart_packages, class_name: 'Package'
  has_one :order_transport, dependent: :destroy
  has_many :process_checklists, through: :orders_process_checklists
  has_many :orders_process_checklists, inverse_of: :order

  after_initialize :set_initial_state
  after_create :update_orders_packages_quantity, if: :draft_goodcity_order?
  after_update :update_orders_packages_quantity, if: :draft_goodcity_order?
  before_create :assign_code

  after_destroy :delete_orders_packages

  accepts_nested_attributes_for :beneficiary
  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :orders_process_checklists, allow_destroy: true

  INACTIVE_STATUS = ['Closed', 'Sent', 'Cancelled'].freeze

  INACTIVE_STATES = ['cancelled', 'closed', 'draft'].freeze

  MY_ORDERS_AUTHORISED_STATES = ['submitted', 'closed', 'cancelled', 'processing', 'awaiting_dispatch', 'dispatching'].freeze

  scope :non_draft_orders, -> { where.not("state = 'draft' AND detail_type = 'GoodCity'") }

  scope :with_eager_load, -> {
    includes([
      { packages: [:locations, :package_type] }
    ])
  }

  scope :descending, -> { order('id desc') }

  scope :active_orders, -> { where('status NOT IN (?) or orders.state NOT IN (?)', INACTIVE_STATUS, INACTIVE_STATES) }

  scope :designatable_orders, -> {
    query = <<-SQL
      (
        submitted_at IS NOT NULL
        AND (status NOT IN (:inactive_status) OR orders.state NOT IN (:inactive_states))
      )
      OR (state = 'draft' AND detail_type != 'GoodCity')
    SQL
    where(query, inactive_status: INACTIVE_STATUS, inactive_states: INACTIVE_STATES)
  }

  scope :my_orders, -> { where("created_by_id = (?) and ((state = 'draft' and submitted_by_id is NULL) OR state IN (?))", User.current_user.try(:id), MY_ORDERS_AUTHORISED_STATES) }

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
      transition all - [:closed] => :cancelled
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
        order.send_new_order_notification
        order.send_new_order_confirmed_sms_to_charity
      end
    end

    after_transition on: :finish_processing do |order|
      if order.awaiting_dispatch?
        order.send_confirmation_email
      end
    end
  end

  def can_transition
    return true unless processing?
    required_process_checks = ProcessChecklist.for_booking_type(booking_type)
    return (required_process_checks - process_checklists).empty?
  end

  def send_confirmation_email
    return if booking_type != BookingType.appointment || created_by.nil?
    begin
      SendgridService.new(created_by).send_appointment_confirmation_email self
    rescue => e
      Rollbar.error(e, error_class: "Sendgrid Error", error_message: "Sendgrid confirmation email")
    end
  end

  def send_new_order_notification
    PushService.new.send_notification(Channel::ORDER_FULFILMENT_CHANNEL, STOCK_APP, {
      category:   'new_order',
      message:    I18n.t('twilio.order_submitted_sms_to_order_fulfilment_users',
        code: code, submitter_name: created_by.full_name,
        organisation_name: organisation.try(:name_en)),
      order_id:   id,
      author_id:  created_by_id
    })
  end

  def send_new_order_confirmed_sms_to_charity
    TwilioService.new(created_by).order_confirmed_sms_to_charity(self)
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
    sql = <<-SQL
      code ILIKE (:query) OR
      description ILIKE (:query) OR
      organisations.name_en ILIKE (:query) OR
      organisations.name_zh_tw ILIKE (:query) OR
      stockit_organisations.name ILIKE (:query) OR
      stockit_local_orders.client_name ILIKE (:query) OR
      stockit_contacts.first_name ILIKE (:query) OR stockit_contacts.last_name ILIKE (:query) OR
      stockit_contacts.mobile_phone_number LIKE (:query) OR
      stockit_contacts.phone_number LIKE (:query) OR
      CONCAT(users.first_name, ' ', users.last_name) ILIKE (:query)
    SQL
    results = fetch_orders(to_designate_item)
    results = results.where(sql, query: "%#{search_text}%") unless search_text.blank?
    results
  end

  def self.fetch_orders(to_designate_item)
    if to_designate_item
      join_order_associations.designatable_orders
    else
      join_order_associations.non_draft_orders
    end
  end

  def self.join_order_associations
    joins <<-SQL
      LEFT OUTER JOIN stockit_local_orders ON orders.detail_id = stockit_local_orders.id and orders.detail_type = 'LocalOrder'
      LEFT OUTER JOIN users ON orders.submitted_by_id = users.id or orders.created_by_id = users.id
      LEFT OUTER JOIN stockit_contacts ON orders.stockit_contact_id = stockit_contacts.id
      LEFT OUTER JOIN stockit_organisations ON orders.stockit_organisation_id = stockit_organisations.id
      LEFT OUTER JOIN organisations ON orders.organisation_id = organisations.id
    SQL
  end

  def self.recently_used(user_id)
    Order.find_by_sql(
      ["select orders.*, versions.created_at AS versions_created_at, versions.item_type, orders_packages.updated_at AS orders_package_updated_at
          from orders
          left join goodcity_requests on goodcity_requests.order_id = orders.id
          join versions on versions.item_type in ('Order', 'GoodcityRequest') AND (versions.item_id = orders.id OR versions.item_id = goodcity_requests.id)
          LEFT join orders_packages on orders_packages.order_id = orders.id AND orders_packages.updated_by_id = ?
          where orders.detail_type='GoodCity' AND versions.whodunnit = ? AND (orders.state not in ('cancelled', 'closed', 'draft') OR orders.status not in ('Closed', 'Sent', 'Cancelled'))
          order by GREATEST(orders_packages.updated_at, versions.created_at) DESC", user_id, user_id.to_s]
    ).uniq.first(5)
  end

  def self.non_priority_active_orders_count
    active_orders_count_as_per_priority_and_state(is_priority: false)
  end

  def self.priority_active_orders_count
    active_orders_count_as_per_priority_and_state(is_priority: true)
  end

  def self.active_orders_count_as_per_priority_and_state(is_priority: false)
    orders = filter(states: ACTIVE_ORDERS, priority: is_priority).group_by(&:state)
    if is_priority
      orders_count_per_state(orders).transform_keys { |key| "priority_".concat(key) }
    else
      orders_count_per_state(orders)
    end
  end

  def self.orders_count_per_state(orders)
    orders.each { |key, value|  orders[key] = value.count }
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

  def email_properties
    props = {}
    props["order_code"] = code
    props["order_id"] = id
    if order_transport
      props["scheduled_at"] = order_transport.scheduled_at.in_time_zone.strftime("%e %b %Y %H:%M%p")
    end
    if beneficiary.present?
      props["client"] = {
        name: beneficiary.first_name + ' ' + beneficiary.last_name,
        phone: beneficiary.phone_number,
        id_type: beneficiary.identity_type.name_en,
        id_no: beneficiary.identity_number
      }
    end
    props['requests'] = goodcity_requests.map do |gc|
      {
        quantity: gc.quantity,
        type_en: gc.package_type.name_en,
        type_zh_tw: gc.package_type.name_zh_tw,
        description: gc.description
      }
    end
    props
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
