class OrdersPackage < ActiveRecord::Base
  belongs_to :order
  belongs_to :package
  belongs_to :updated_by, class_name: 'User'

  after_initialize :set_initial_state
  after_create -> { recalculate_quantity("create") }
  after_update -> { recalculate_quantity("update") }
  after_destroy -> { destroy_stockit_record("destroy") }
  scope :get_records_associated_with_order_id, -> (order_id) { where(order_id: order_id) }
  scope :get_designated_and_dispatched_packages, -> (package_id, state1, state2) { where("package_id = (?) and (state = (?) or state = (?))", package_id, state1, state2) }
  scope :get_records_associated_with_package_and_order, -> (order_id, package_id) { where("order_id = ? and package_id = ?", order_id, package_id) }

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
      transition designated: :dispatched
    end

    after_transition on: :dispatch, do: :assign_dispatched_location
  end

  def assign_dispatched_location
    location = Location.dispatch_location
    package.packages_locations.create(
      location: location,
      quantity: quantity,
      reference_to_orders_package: id
    )
  end

  def undispatch_orders_package
    update(state: "designated", sent_on: nil)
  end

  def update_designation(order_id_to_update)
    update(order_id: order_id_to_update)
  end

  def delete_unwanted_cancelled_packages(order_to_delete)
    OrdersPackage.where("order_id = ? and package_id = ? and state = ?", order_to_delete, package_id, "cancelled").destroy_all
  end

  def update_partially_designated_item(package)
    total_quantity = quantity + package[:quantity].to_i
    if(state == "cancelled")
      update(quantity: total_quantity, state: "designated")
    else
      update(quantity: total_quantity)
    end
  end

  def dispatch_orders_package
    update(sent_on: Date.today, state_event: "dispatch")
  end

  def self.undesignate_partially_designated_item(packages)
    packages.each do |package|
      quantity_to_reduce = package.last[:quantity].to_i
      orders_package = find_by_id(package.last[:orders_package_id])
      total_quantity = orders_package.quantity - quantity_to_reduce
      update_orders_package_state(orders_package, total_quantity)
    end
  end

  def self.update_orders_package_state(orders_package, total_quantity)
    if total_quantity == 0
      orders_package.update(quantity: total_quantity, state: "cancelled")
    else
      orders_package.update(quantity: total_quantity, state: "designated")
    end
  end

  def self.add_partially_designated_item(package)
    create(
      order_id: package[:order_id].to_i,
      package_id: package[:package_id].to_i,
      quantity: package[:quantity].to_i,
      updated_by: User.current_user,
      state: "designated"
      )
  end

  private
  def recalculate_quantity(operation)
    unless(state == "requested")
      update_designation_of_package
      package = Package.find_by_id(package_id)
      package.update_in_stock_quantity(get_total_quantity)
      StockitSyncOrdersPackageJob.perform_later(package.id, self.id, operation)
    end
  end

  def update_designation_of_package
    orders_packages = package.orders_packages.where(state: 'designated')
    if package && orders_packages.count == 1
      package.update_designation(orders_packages.first.order_id)
    elsif orders_packages.count == 0
      package.remove_designation
    end
  end

  def get_total_quantity
    total_quantity = 0
    orders_packages = OrdersPackage.get_designated_and_dispatched_packages(package_id, "designated", "dispatched")
    orders_packages.each do |orders_package|
      total_quantity += orders_package.quantity
    end
    total_quantity
  end

  def destroy_stockit_record(operation)
    StockitSyncOrdersPackageJob.perform_now(package.id, self.id, operation)
  end
end
