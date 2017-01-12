class OrdersPackage < ActiveRecord::Base
  belongs_to :order
  belongs_to :package
  belongs_to :updated_by, class_name: 'User'

  after_initialize :set_initial_state
  after_create -> { recalculate_quantity("create") }
  after_update -> { recalculate_quantity("update") }
  after_destroy -> { destroy_stockit_record("destroy") }
  scope :get_records_associated_with_order_id, -> (order_id) { where(order_id: order_id) }
  scope :get_records_by_state, -> (package_id, state) { where("package_id = (?) and state = (?)", package_id, state) }
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
    update(sent_on: Date.today, state: "dispatched")
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
    update_designation_of_package
    package = Package.find_by_id(package_id)
    package.update_in_stock_quantity(get_total_quantity)
    StockitSyncOrdersPackageJob.perform_now(package.id, self, operation)
  end

  def update_designation_of_package
    designate_orders_packages = OrdersPackage.get_records_by_state(package_id, "designated")
    package = Package.find_by_id(designate_orders_packages.first.package_id) if designate_orders_packages.first.present?
    change_package_designation(designate_orders_packages, package) if package.present?
  end

  def change_package_designation(designate_orders_packages, package)
    if(designate_orders_packages.length == 1)
      package.update_designation(designate_orders_packages.first.order_id)
    elsif(designate_orders_packages.length == 0)
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
    StockitSyncOrdersPackageJob.perform_now(package.id, self, operation)
  end
end
