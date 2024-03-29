# frozen_string_literal: true

class Order < ApplicationRecord
  has_paper_trail versions: { class_name: "Version" }
  include PushUpdatesMinimal
  include OrderFiltering
  include OrderCodeGenerator

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    [
      Channel.private_channels_for(record.created_by, BROWSE_APP),
      Channel::ORDER_FULFILMENT_CHANNEL
    ]
  end

  module DetailType
    SHIPMENT = 'Shipment'
    GOODCITY = 'GoodCity'
    CARRYOUT = 'CarryOut'
  end

  belongs_to :cancellation_reason
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
  belongs_to :created_by, class_name: "User"
  belongs_to :processed_by, class_name: "User"
  belongs_to :cancelled_by, class_name: "User"
  belongs_to :process_completed_by, class_name: "User"
  belongs_to :dispatch_started_by, class_name: "User"
  belongs_to :closed_by, class_name: "User"
  belongs_to :submitted_by, class_name: "User"
  belongs_to :stockit_local_order, -> { joins("inner join orders on orders.detail_id = stockit_local_orders.id and (orders.detail_type = 'LocalOrder' or orders.detail_type = 'StockitLocalOrder')") }, foreign_key: "detail_id"

  has_many :packages
  has_many :goodcity_requests, dependent: :destroy
  has_many :orders_purposes, dependent: :destroy
  has_many :purposes, through: :orders_purposes
  has_many :orders_packages, dependent: :destroy
  has_many :messages, as: :messageable, dependent: :destroy
  has_many :subscriptions, as: :subscribable, dependent: :destroy
  has_one :order_transport, dependent: :destroy
  has_many :orders_process_checklists, inverse_of: :order
  has_many :process_checklists, through: :orders_process_checklists

  before_validation :assign_code, on: [:create]
  validates :people_helped, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validate :validate_shipment_date, on: %i[create], if: :shipment_order?
  validate :validate_code_format, on: %i[create update]
  validates_uniqueness_of :code
  validates_presence_of :code

  after_initialize :set_initial_state

  after_destroy :delete_orders_packages

  accepts_nested_attributes_for :beneficiary
  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :orders_process_checklists, allow_destroy: true

  INACTIVE_STATES = ["cancelled", "closed", "draft"].freeze

  ACTIVE_STATES = ["submitted", "processing", "awaiting_dispatch", "dispatching"].freeze

  MY_ORDERS_AUTHORISED_STATES = ["submitted", "closed", "cancelled", "processing", "awaiting_dispatch", "dispatching"].freeze

  NON_PROCESSED_STATES = ["processing", "submitted", "draft"].freeze

  ORDER_UNPROCESSED_STATES = [INACTIVE_STATES, "submitted", "processing", "draft"].flatten.uniq.freeze

  scope :non_draft_orders, -> { where.not("orders.state = 'draft' AND detail_type = 'GoodCity'") }
  scope :closed, -> { where(state: 'closed') }
  scope :with_eager_load, -> {
          includes([:subscriptions, :order_transport,
                    { packages: [:locations, :package_type] }])
        }

  scope :descending, -> { order("orders.id desc") }
  scope :active_orders, -> { where("orders.state NOT IN (?)", INACTIVE_STATES) }

  scope :designatable_orders, -> {
          query = <<-SQL
      (
        submitted_at IS NOT NULL
        AND (orders.state NOT IN (:inactive_states))
      )
      OR (state = 'draft' AND detail_type != 'GoodCity')
    SQL
          where(query, inactive_states: INACTIVE_STATES)
        }

  scope :my_orders, -> { where("created_by_id = (?) and ((state = 'draft' and submitted_by_id is NULL) OR state IN (?))", User.current_user.try(:id), MY_ORDERS_AUTHORISED_STATES) }

  scope :goodcity_orders, -> { where(detail_type: Order::DetailType::GOODCITY) }
  scope :shipments, -> { where(detail_type: Order::DetailType::SHIPMENT) }

  def can_dispatch_item?
    ORDER_UNPROCESSED_STATES.include?(state)
  end

  def self.counts_for(created_by_id)
    where.not(state: "draft").group(:state).where(created_by_id: created_by_id).count
  end

  def delete_orders_packages
    if self.orders_packages.exists?
      orders_packages.map(&:destroy)
    end
  end

  def update_transition_and_reason(event, cancel_opts)
    fire_state_event(event)
    opts = cancel_opts.select { |k| [:cancellation_reason_id, :cancel_reason].include?(k) }
    update(opts)
  end

  def designate_orders_packages
    orders_packages.each do |orders_package|
      orders_package.update_state_to_designated
    end
  end

  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    state :submitted, :processing, :closed, :cancelled, :awaiting_dispatch, :restart_process, :dispatching, :start_dispatching

    event :submit do
      transition [:draft, :submitted] => :submitted
      transition processing: :processing
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
      if order.booking_type&.online_order? && order.orders_packages.length.zero? && order.state != 'draft'
        raise Goodcity::InvalidStateError, I18n.t('order.orders_package_should_exist')
      end
      order.submitted_at = Time.now
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
      if OrdersPackage.for_order(order.id).not_cancellable.exists?
        raise Goodcity::InvalidStateError.new(I18n.t('orders_package.cancel_requires_undispatch'))
      end

      order.cancelled_at = Time.now
      order.cancelled_by = User.current_user
      order.orders_packages.each do |orders_package|
        orders_package.cancel
      end
    end

    before_transition on: :close do |order|
      if order.orders_packages.designated.count.positive?
        raise Goodcity::InvalidStateError.new(I18n.t('order.cannot_close_with_undispatched_packages'))
      end

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
        order.nullify_columns(:cancellation_reason_id, :cancel_reason, :processed_at, :processed_by_id, :process_completed_at, :process_completed_by_id,
                              :cancelled_at, :cancelled_by_id, :dispatch_started_by_id, :dispatch_started_at)
      end
    end

    after_transition on: :submit do |order|
      if order.goodcity_order?
        order.designate_orders_packages
        order.send_new_order_notification
        order.send_new_order_confirmed_sms_to_charity
        order.send_order_submission_email
      end
    end

    after_transition on: :finish_processing do |order|
      if order.awaiting_dispatch? && order.valid_detail_type?
        order.send_confirmation_email
      end
    end
  end

  def can_transition
    return true unless processing?
    required_process_checks = ProcessChecklist.for_booking_type(booking_type)
    return (required_process_checks - process_checklists).empty?
  end

  def send_submission_pickup_email?
    booking_type.appointment? || order_transport&.pickup?
  end

  def send_order_submission_email
    return if created_by.nil? || !state.eql?('submitted')

    if send_submission_pickup_email?
      mailer.send_order_submission_pickup_email.deliver_later
    else
      mailer.send_order_submission_delivery_email.deliver_later
    end
  end

  def send_confirmation_email
    send_appointment_confirmation_email if booking_type&.appointment?
    send_online_order_confirmation_email if booking_type&.online_order?
  end

  def send_appointment_confirmation_email
    return unless booking_type.appointment? && created_by.present?

    mailer.send_appointment_confirmation_email.deliver_later
  end

  def send_online_order_confirmation_email
    return unless booking_type.online_order? && created_by.present?

    if order_transport.pickup?
      mailer.send_order_confirmation_pickup_email.deliver_later
    else
      mailer.send_order_confirmation_delivery_email.deliver_later
    end
  end

  def send_new_order_notification
    PushService.new.send_notification(Channel::ORDER_FULFILMENT_CHANNEL, STOCK_APP,
    {
      category: "new_order",
      message: I18n.t("twilio.order_submitted_sms_to_order_fulfilment_users",
                      code: code, submitter_name: created_by.full_name,
                      organisation_name: organisation.try(:name_en)),
      order_id: id,
      author_id: created_by_id
    })
  end

  def send_new_order_confirmed_sms_to_charity
    TwilioService.new(created_by).order_confirmed_sms_to_charity(self)
  end

  def shipment_order?
    detail_type == DetailType::SHIPMENT
  end

  def nullify_columns(*columns)
    columns.map { |column| send("#{column}=", nil) }
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
      beneficiaries.first_name ILIKE (:query) OR beneficiaries.last_name ILIKE (:query) OR
      CONCAT(beneficiaries.first_name, ' ', beneficiaries.last_name) ILIKE (:query) OR
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
      LEFT OUTER JOIN beneficiaries ON orders.beneficiary_id = beneficiaries.id
    SQL
  end

  def self.recently_used(user_id)
    Order.find_by_sql(
      ["select orders.*, versions.created_at AS versions_created_at, versions.item_type, orders_packages.updated_at AS orders_package_updated_at
          from orders
          left join goodcity_requests on goodcity_requests.order_id = orders.id
          join versions on versions.item_type in ('Order', 'GoodcityRequest') AND (versions.item_id = orders.id OR versions.item_id = goodcity_requests.id)
          LEFT join orders_packages on orders_packages.order_id = orders.id AND orders_packages.updated_by_id = ?
          where orders.detail_type='GoodCity' AND versions.whodunnit = ? AND (orders.state not in ('cancelled', 'closed', 'draft'))
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
    orders = apply_filter(states: ACTIVE_ORDERS, priority: is_priority, types: GOODCITY_BOOKING_TYPES).group_by(&:state)
    if is_priority
      orders_count_per_state(orders).transform_keys { |key| "priority_#{key}" }
    else
      orders_count_per_state(orders)
    end
  end

  def self.orders_count_per_state(orders)
    orders.each { |key, value| orders[key] = value.count }
  end

  def valid_detail_type?
    [DetailType::SHIPMENT, DetailType::GOODCITY, DetailType::CARRYOUT].include? detail_type
  end

  def goodcity_order?
    detail_type == DetailType::GOODCITY
  end

  def email_properties
    props = {}
    props["order_code"] = code
    props["order_id"] = id
    props["booking_type"] = booking_type.name_en
    props["booking_type_zh"] = booking_type.name_zh_tw
    props["domain"] = Rails.env.staging? ? "browse-staging" : "browse"
    if order_transport
      if booking_type.appointment?
        format = "%e %b %Y %H:%M%p"
      else
        format = "%e %b %Y %p"
      end
      props["scheduled_at"] = order_transport.scheduled_at.in_time_zone.strftime(format)
    end
    if beneficiary.present?
      props["client"] = {
        name: beneficiary.first_name + " " + beneficiary.last_name,
        phone: beneficiary.phone_number,
        id_type: beneficiary.identity_type.name_en,
        id_no: beneficiary.identity_number
      }
    end
    props["requests"] = goodcity_requests.map do |gc|
      {
        quantity: gc.quantity,
        type_en: gc.package_type.name_en,
        type_zh_tw: gc.package_type.name_zh_tw.present? ? gc.package_type.name_zh_tw : gc.package_type.name_en,
        description: gc.description
      }
    end
    props["goods"] = orders_packages.select(&:designated?).map do |op|
      {
        quantity: op.quantity,
        type_en: op.package.package_type.name_en,
        type_zh_tw: op.package.package_type.name_zh_tw.present? ? op.package.package_type.name_zh_tw : op.package.package_type.name_en
      }
    end
    props
  end

  private

  def assign_code
    return if code.present?

    self.code = Order.generate_next_code_for(detail_type) if valid_detail_type?
  end

  def mailer
    GoodcityOrderMailer.with(order_id: id, user_id: created_by_id)
  end

  #to satisfy push_updates
  def order
    self
  end

  #to satisfy push_updates
  def offer
    nil
  end

  def validate_shipment_date
    is_valid = shipment_date >= Date.current
    errors.add(:error, I18n.t('order.errors.shipment_date')) unless is_valid
  end

  def validate_code_format
    reg = nil
    case detail_type
    when DetailType::GOODCITY
      reg = /^GC-[0-9]{5}/
    when DetailType::SHIPMENT
      reg = /^S[0-9]{4,5}[A-Z]{1}?/
    when DetailType::CARRYOUT
      reg = /^C[0-9]{4,5}[A-Z]{1}?/
    else
      reg = /[A-Z0-9]+/
    end
    errors.add(:base, I18n.t('order.errors.invalid_code_format')) unless reg.match?(code)
  end
end
