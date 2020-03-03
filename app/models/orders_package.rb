class OrdersPackage < ActiveRecord::Base
  include RollbarSpecification
  include OrdersPackageActions
  include HookControls

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
  after_create -> { push_to_stockit("create") }
  after_update -> { push_to_stockit("update") }
  before_destroy -> { push_to_stockit("destroy") }
  managed_hook :save, :before, :assert_availability!

  scope :get_records_associated_with_order_id, ->(order_id) { where(order_id: order_id) }
  scope :get_designated_and_dispatched_packages, ->(package_id) { where("package_id = (?) and state IN (?)", package_id, ['designated', 'dispatched']) }
  scope :get_records_associated_with_package_and_order, ->(order_id, package_id) { where("order_id = ? and package_id = ?", order_id, package_id) }
  scope :designated, ->{ where(state: 'designated') }
  scope :dispatched, ->{ where(state: 'dispatched') }
  scope :for_order, ->(order_id) { joins(:order).where(orders: { id: order_id }) }
  scope :not_cancellable, -> () { where("orders_packages.state = 'dispatched' OR dispatched_quantity > 0") }
  scope :cancellable, -> () { where("orders_packages.state = 'designated' AND dispatched_quantity = 0") }

  scope :with_eager_load, ->{
    includes([
      { package: [ :locations, {package_type: [:location]}, :images, :orders_packages] }
    ])
  }

  PackagesInventory.on [:dispatch, :undispatch] do |pkg_inv|
    # Compute 'dispatched_quantity' column on change
    if pkg_inv.source_id.present? && pkg_inv.source_type.eql?('OrdersPackage')
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
      orders_package.quantity   = 0
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

  def update_designation(order_id_to_update)
    update(order_id: order_id_to_update, updated_by: User.current_user)
  end

  def redesignate(new_order_id)
    ActiveRecord::Base.transaction do
      update_designation new_order_id
      update_state_to_designated
    end
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


  def push_to_stockit(operation)
    return if state == "requested" || GoodcitySync.request_from_stockit
    StockitSyncOrdersPackageJob.perform_now(package.id, self.id, operation) unless package.singleton_package?
  end
end
