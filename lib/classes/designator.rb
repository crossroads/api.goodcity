class Designator
  attr_accessor :package, :params, :order_id, :orders_package

  def initialize(package, package_params)
    @package = package
    @params = package_params
    @order_id = package_params[:order_id].to_i
    @orders_package = @package.orders_packages.new
  end

  def designated?
    @params[:quantity].to_i.zero?
  end

  def designate_stockit_item
    @package.designate_to_stockit_order(@order_id_param)
  end

  def check_designated_and_designate_item
    if designated?
      if already_designated_to_same_order?&.errors
        return already_designated_to_same_order?
      else
        undesignate_before_designate
      end
    end
    designate_to_goodcity_and_stockit
  end

  def already_designated_to_same_order?
    orders_package = OrdersPackage.find_by_id(@params[:orders_package_id])
    return add_error(orders_package,"order_id", "Already designated to this Order") if orders_package.try(:order_id) === @order_id
  end

  def undesignate_before_designate
    undesignate_package = {}
    @params[:quantity] = @params[:received_quantity]
    undesignate_package["0"] = @params
    undesignate(undesignate_package)
  end

  def undesignate(undesignate_package = nil)
    packages = undesignate_package ? undesignate_package : @params
    OrdersPackage.undesignate_partially_designated_item(packages)
    @package.undesignate_from_stockit_order
  end

  def designate_to_goodcity_and_stockit
    return designate if designate.errors
    designate_stockit_item
  end

  def designate
    @orders_package.order_id = @order_id
    @orders_package.quantity = quantity.to_i
    @orders_package.updated_by = User.current_user
    @orders_package.state = 'designated'
    @orders_package.save
    @orders_package
  end

  def quantity
    @params[:quantity].to_i.zero? ? @params[:received_quantity] : @params[:quantity]
  end

  def add_error(orders_package, field, message)
    orders_package.errors.add(field, message)
    orders_package
  end

end
