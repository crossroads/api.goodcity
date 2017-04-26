class Order < ActiveRecord::Base
  belongs_to :detail, polymorphic: true
  belongs_to :stockit_activity
  belongs_to :country
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
  belongs_to :organisation
  belongs_to :created_by, class_name: 'User'
  belongs_to :processed_by, class_name: 'User'
  belongs_to :stockit_local_order, -> { joins("inner join orders on orders.detail_id = stockit_local_orders.id and orders.detail_type = 'LocalOrder'") }, foreign_key: 'detail_id'

  has_many :packages
  has_and_belongs_to_many :purposes
  has_many :orders_packages
  has_and_belongs_to_many :cart_packages, class_name: 'Package'
  has_one :order_transport

  after_initialize :set_initial_state
  after_create :update_orders_packages_quantity, if: :state_is_draft_and_detail_type_is_goodcity?
  before_create :assign_code

  INACTIVE_STATUS = ['Closed', 'Sent', 'Cancelled']

  scope :with_eager_load, -> {
    includes([
      { packages: [:locations, :package_type] }
    ])
  }

  scope :latest, -> { order('id desc') }

  scope :active_orders, -> { where('status NOT IN (?)', INACTIVE_STATUS) }

  def designate_orders_packages
    orders_packages.each do |orders_package|
      orders_package.update_state_to_designated
    end
  end

  def state_is_draft_and_detail_type_is_goodcity?
    state == "draft" && detail_type == "GoodCity"
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
    state :submitted, :processing, :closed, :cancelled

    event :submit do
      transition :draft => :submitted
    end

    event :start_processing do
      transition :submitted => :processing
    end

    before_transition on: :submit do |order|
      order.add_to_stockit
    end

    after_transition on: :submit do |order|
      order.designate_orders_packages if (order.detail_type == "GoodCity")
    end
  end

  def add_to_stockit
    response = Stockit::DesignationSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    elsif response && (designation_id = response["designation_id"]).present?
      self.stockit_id = designation_id
    end
  end

  def self.search(search_text, to_designate_item)
    fetch_orders(to_designate_item)
    .where(" code LIKE :query OR stockit_organisations.name LIKE :query OR
      stockit_local_orders.client_name LIKE :query OR
      stockit_contacts.first_name LIKE :query OR stockit_contacts.last_name LIKE :query OR
      stockit_contacts.mobile_phone_number LIKE :query OR
      stockit_contacts.phone_number LIKE :query", query: "%#{search_text}%")
  end

  def self.fetch_orders(to_designate_item)
    if to_designate_item
      join_order_associations.active_orders
    else
      join_order_associations
    end
  end

  def self.join_order_associations
    joins("LEFT OUTER JOIN stockit_local_orders ON orders.detail_id = stockit_local_orders.id and orders.detail_type = 'LocalOrder'LEFT OUTER JOIN stockit_contacts ON orders.stockit_contact_id = stockit_contacts.id LEFT OUTER JOIN stockit_organisations ON orders.stockit_organisation_id = stockit_organisations.id")
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
    code = record ? record.code.gsub(/\D/, '').to_i + 1 : 1
    "GC-" + code.to_s.rjust(5, "0")
  end

  private

  def assign_code
    self.code = Order.generate_gc_code if detail_type == "GoodCity"
  end
end
