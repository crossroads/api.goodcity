class Designator
  attr_accessor :package, :params, :order_id, :orders_package

  def initialize(package, package_params)
    @package = package
    @params = package_params
    @order_id = package_params[:order_id].to_i
    @orders_package = build_or_find_orders_package
    @existing_orders_package = existing_orders_package
    @orders_package.quantity = @params[:quantity_to_designate] ? @params[:quantity_to_designate] :  @params[:quantity]
    @orders_package.order_id = package_params[:order_id].to_i
  end

  def build_or_find_orders_package
    if existing_orders_package&.order_id == @params[:order_id].to_i
      existing_orders_package
    else
      @package.orders_packages.new
    end
  end

  def designate
    if @orders_package.valid?
      redesignate if @existing_orders_package&.designated?
      designate_item
    else
      @orders_package
    end
  end

  # undesignate_package params is passed from redesignate
  def undesignate(undesignate_package = nil)
    packages = undesignate_package ? undesignate_package : @params
    OrdersPackage.undesignate_partially_designated_item(packages)
    @package.undesignate_from_stockit_order
  end

  def redesignate
    undesignate_package = {}
    @params[:quantity] = @package.received_quantity
    undesignate_package["0"] = @params
    undesignate(undesignate_package)
  end

  private

  def existing_orders_package
    orders_package ||= OrdersPackage.find_by_id(@params[:orders_package_id]) if @params[:orders_package_id]
  end

  def designate_item
    @orders_package.updated_by = User.current_user
    @orders_package.state = 'designated'
    @orders_package.save
    @orders_package
  end
end
