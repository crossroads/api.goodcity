class Designator
  attr_accessor :package, :params, :order_id, :orders_package

  def initialize(package, package_params)
    @package = package
    @params = package_params
    @order_id = package_params[:order_id].to_i
    @orders_package = @package.orders_packages.new
  end

  # checks if already designated before redesignating
  def designate
    return designated_to_existing_order_error if existing_orders_package_error&.errors.present?
    redesignate if designated?
    designate_to_goodcity_and_stockit
  end

  # undesignate_package params is passed from redesignate
  def undesignate(undesignate_package = nil)
    packages = undesignate_package ? undesignate_package : @params
    OrdersPackage.undesignate_partially_designated_item(packages)
    @package.undesignate_from_stockit_order
  end

  def redesignate
    undesignate_package = {}
    @params[:quantity] = @params[:received_quantity]
    undesignate_package["0"] = @params
    undesignate(undesignate_package)
  end

  private

  def designated?
    @params[:quantity].eql?("0")
  end

  def quantity
    designated? ? @params[:received_quantity] : @params[:quantity]
  end

  def designate_to_goodcity_and_stockit
    return designate_item if designate_item.errors
    designate_stockit_item
  end

  def designate_stockit_item
    @package.designate_to_stockit_order(@order_id)
  end

  def designate_item
    @orders_package.order_id = @order_id
    @orders_package.quantity = quantity.to_i
    @orders_package.updated_by = User.current_user
    @orders_package.state = 'designated'
    @orders_package.save
    @orders_package
  end

  def designated_to_existing_order_error
    existing_orders_package_error if designated?
  end

  def existing_orders_package_error
    orders_package = OrdersPackage.find_by_id(@params[:orders_package_id])
    orders_package&.check_valid_order!(@order_id)
    orders_package
  end
end
