class OrdersPackage < ActiveRecord::Base
  belongs_to :order
  belongs_to :package
  belongs_to :updated_by, class_name: 'User'

  after_initialize :set_initial_state
  after_create :recalculte_quantity
  after_update :recalculte_quantity

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

  def self.update_partially_designated_item(package)
    orders_package = OrdersPackage.find(package[:orders_package_id].to_i)
    total_quantity = orders_package.quantity + package[:quantity].to_i
    if(orders_package.state == "cancelled")
      orders_package.update(quantity: total_quantity, state: "designated")
    else
      orders_package.update(quantity: total_quantity)
    end
  end

  def self.undesignate_partially_designated_item(packages)
    packages.each do |package|
      quantity_to_reduce = package.last[:quantity].to_i
      orders_package = OrdersPackage.find(package.last[:orders_package_id].to_i)
      total_quantity = orders_package.quantity - quantity_to_reduce
      if total_quantity == 0
        orders_package.update(quantity: total_quantity, state: "cancelled")
      else
        orders_package.update(quantity: total_quantity, state: "designated")
      end
    end
  end

  def self.add_partially_designated_item(package)
    self.create(
      order_id: package[:order_id].to_i,
      package_id: package[:package_id].to_i,
      quantity: package[:quantity].to_i,
      updated_by: User.current_user,
      state: "designated"
      )
  end

  def self.find_packages(order_id, package_id)
    OrdersPackage.where("order_id = ? and package_id = ?", order_id, package_id)
  end

  def self.dispatch_orders_package(orders_package_id)
    orders_package = OrdersPackage.find(orders_package_id)
    orders_package.update(sent_on: Date.today)
  end

  private
  def recalculte_quantity
    total_quantity = 0
    orders_packages = OrdersPackage.filter_packages_by_state(package_id, "designated")
    if(orders_packages.length == 1)
      Package.update_designation(orders_packages.first.package_id, orders_packages.first.order_id)
    elsif(orders_packages.length == 0)
      Package.remove_designation(package_id)
    end
    orders_packages.each do |orders_package|
      total_quantity += orders_package.quantity
    end
    Package.update_in_stock_quantity(package_id, total_quantity)
  end

  def self.filter_packages_by_state(package_id, state)
    where("package_id = (?) and state = (?)", package_id, state)
  end
end
