class OrdersPackage < ApplicationRecord

  include OrdersPackageActions
  include HookControls
  include Watcher
  include OrdersPackageSearch

  module States
    DESIGNATED = 'designated'.freeze
    DISPATCHED = 'dispatched'.freeze
    CANCELLED  = 'cancelled'.freeze
  end

  belongs_to :order
  belongs_to :package
  belongs_to :updated_by, class_name: 'User'
  validates :quantity,  numericality: { greater_than_or_equal_to: 0 }
  validates :package, :order, :quantity, presence: true
  after_initialize :set_initial_state
  managed_hook :save, :before, :assert_availability!

  scope :get_records_associated_with_order_id, ->(order_id) { where(order_id: order_id) }
  scope :get_designated_and_dispatched_packages, ->(package_id) { where("package_id = (?) and state IN (?)", package_id, ['designated', 'dispatched']) }
  scope :get_records_associated_with_package_and_order, ->(order_id, package_id) { where("order_id = ? and package_id = ?", order_id, package_id) }
  scope :designated, ->{ where(state: 'designated') }
  scope :dispatched, ->{ where(state: 'dispatched') }
  scope :for_order, ->(order_id) { joins(:order).where(orders: { id: order_id }) }
  scope :not_cancellable, -> () { where("orders_packages.state = 'dispatched' OR dispatched_quantity > 0") }
  scope :cancellable, -> () { where("orders_packages.state = 'designated' AND dispatched_quantity = 0") }
  scope :sorting, -> (options) { order(sort_orders_package(options)) }
  scope :by_state, ->(states) { where("orders_packages.state IN (?)", states) }

  scope :with_eager_load, ->{
    includes([
      { package: [ :locations, {package_type: [:location]}, :images, :orders_packages] }
    ])
  }

  def self.search_and_filter(options)
    orders_packages = joins(package: [:package_type])
    orders_packages = orders_packages.select("orders_packages.*, package_types.code, package_types.name_en, packages.inventory_number")
    orders_packages = orders_packages.search(options) if options[:search_text]
    orders_packages = orders_packages.by_state(options[:state_names]) if options[:state_names]&.any?
    orders_packages = orders_packages.sorting(options) if options[:sort_column]
    orders_packages
  end

  def self.sort_orders_package(options)
    sort_column = options[:sort_column]
    sort_type = options[:is_desc] ? "DESC" : "ASC"
    "#{sort_column} #{sort_type}"
  end

  watch [PackagesInventory], on: [:create] do |pkg_inv|
    # Compute 'dispatched_quantity' column on change
    dispatch_change = [
      PackagesInventory::Actions::DISPATCH,
      PackagesInventory::Actions::UNDISPATCH
    ].include?(pkg_inv.action)

    if dispatch_change && pkg_inv.source_id.present? && pkg_inv.source_type.eql?('OrdersPackage')
      ord_pkg = pkg_inv.source
      ord_pkg.update(
        dispatched_quantity: PackagesInventory::Computer.dispatched_quantity(orders_package:  ord_pkg)
      )
    end
  end

  def set_initial_state
    self.state ||= :requested
  end

  state_machine :state, initial: :requested do
    state :cancelled, :designated, :received, :dispatched

    event :reject do
      transition requested: :cancelled
    end

    event :designate do
      transition requested: :designated
    end

    event :dispatch do
      transition [:designated, :cancelled] => :dispatched
    end

    event :cancel do
      transition [:requested, :designated] => :cancelled
    end

    before_transition on: :cancel do |orders_package, _transition|
      if orders_package.designated? && orders_package.dispatched_quantity.positive?
        raise Goodcity::InvalidStateError.new(I18n.t('orders_package.cancel_requires_undispatch'))
      end
      orders_package.updated_by = User.current_user
    end

    before_transition on: :dispatch do |orders_package, _transition|
      orders_package.sent_on    =  Time.now
      orders_package.updated_by =  User.current_user
    end

    after_transition on: :dispatch, do: :delete_packages_locations
  end

  # Once a package is dispatched, remove the location entry
  def delete_packages_locations
    if package.singleton_package?
      package.packages_locations.destroy_all
    end
  end

  def undispatch_orders_package
    update(state: "designated", sent_on: nil)
  end

  def update_state_to_designated
    package.unpublish
    update(state: 'designated')
  end

  def delete_unwanted_cancelled_packages(order_to_delete)
    OrdersPackage.where("order_id = ? and package_id = ? and state = ?", order_to_delete, package_id, "cancelled").destroy_all
  end

  def dispatch_orders_package
    self.dispatch
  end

  private

  def assert_availability!
    return if cancelled?

    requires_recompute = !persisted? || (state_changed? && state_was.eql?(States::CANCELLED))
    if requires_recompute && PackagesInventory::Computer.available_quantity_of(package) < quantity
      raise Goodcity::InsufficientQuantityError.new(quantity)
    end
  end
end
