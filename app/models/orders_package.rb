class OrdersPackage < ActiveRecord::Base
  belongs_to :order
  belongs_to :package
  belongs_to :updated_by, class_name: 'User'

  after_initialize :set_initial_state
  # after_create -> { recalculate_quantity("create") }
  # after_update -> { recalculate_quantity("update") }
  before_destroy -> { destroy_stockit_record("destroy") }

  scope :get_records_associated_with_order_id, -> (order_id) { where(order_id: order_id) }
  scope :get_designated_and_dispatched_packages, -> (package_id) { where("package_id = (?) and state IN (?)", package_id, ['designated', 'dispatched']) }
  scope :get_records_associated_with_package_and_order, -> (order_id, package_id) { where("order_id = ? and package_id = ?", order_id, package_id) }
  scope :get_dispatched_records_with_order_id, -> (order_id) { where(order_id: order_id, state: 'dispatched') }
  scope :designated, -> { where(state: 'designated') }

  scope :with_eager_load, -> {
    includes([
      { package: [:locations, :package_type] }
    ])
  }

  def set_initial_state
    self.state ||= :requested
  end

  state_machine :state, initial: :requested do
    state :cancelled, :designated, :received, :dispatched

    event :reject do
      transition :requested => :cancelled
    end

    event :designate do
      transition :requested => :designated
    end

    event :dispatch do
      transition [:designated, :cancelled] => :dispatched
    end

    event :cancel do
      transition designated: :cancelled
    end

    before_transition on: :cancel do |orders_package, _transition|
      orders_package.quantity   = 0
      orders_package.updated_by = User.current_user
    end

    before_transition on: :dispatch do |orders_package, _transition|
      orders_package.sent_on    =  Time.now
      orders_package.updated_by =  User.current_user
    end

    # after_transition on: :dispatch, do: :assign_dispatched_location
  end

  def undispatch_orders_package
    update(state: "designated", sent_on: nil)
  end

  def update_state_to_designated
    package.update_allow_web_publish_to_false
    update(state: 'designated')
  end

  def update_quantity
    update(quantity: package.quantity)
  end

  def update_designation(order_id_to_update)
    update(order_id: order_id_to_update, updated_by: User.current_user)
  end

  def delete_unwanted_cancelled_packages(order_to_delete)
    OrdersPackage.where("order_id = ? and package_id = ? and state = ?", order_to_delete, package_id, "cancelled").destroy_all
  end

  def dispatch_orders_package
    self.dispatch
  end

  def self.add_partially_designated_item(order_id:, package_id:, quantity:)
    create(
      order_id: order_id.to_i,
      package_id: package_id.to_i,
      quantity: quantity.to_i,
      updated_by: User.current_user,
      state: 'designated'
    )
  end

  def save_state_and_quantity(state, quantity)
    state_event = state
    quantity = quantity
    updated_by = User.current_user
    save
  end

  # def save_state_and_quantity(state, quantity)
  #   state_event = state
  #   quantity = quantity
  #   updated_by = User.current_user
  #   save
  # end

  private
  def recalculate_quantity(operation)
    unless(self.requested? || GoodcitySync.request_from_stockit)
      update_designation_of_package
      package.update_in_stock_quantity
      StockitSyncOrdersPackageJob.perform_now(package_id, self.id, operation) unless package.is_singleton_package?
    end
  end

  def update_designation_of_package
    designated_orders_packages = package.orders_packages.where(state: 'designated')
    dispatched_orders_packages = package.orders_packages.where(state: 'dispatched')
    if package && designated_orders_packages.count == 1
      package.update_designation(designated_orders_packages.first.order_id)
    elsif designated_orders_packages.count == 0 && dispatched_orders_packages.count == 0
      package.remove_designation
    end
  end

  def destroy_stockit_record(operation)
    StockitSyncOrdersPackageJob.perform_now(package.id, self.id, operation) unless package.is_singleton_package?
  end
end


