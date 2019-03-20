class Designator

  def initialize(package, package_params)
    @package = package
    @params = package_params
  end

  def designated?
    @params[:quantity].to_i.zero?
  end

  def already_designated_to_same_order?
    orders_package = OrdersPackage.find(@params[:orders_package_id])
    return orders_package.order_id === (@params[:order_id]).to_i
  end

  def undesignate
    undesignate_package = {}
    @params[:quantity] = @params[:received_quantity]
    undesignate_package["0"] = @params
    OrdersPackage.undesignate_partially_designated_item(undesignate_package)
    @package.undesignate_from_stockit_order

  end

  def designate
    OrdersPackage.add_partially_designated_item(
          order_id: @params[:order_id],
          package_id: @params[:package_id],
          quantity: @params[:quantity].to_i.zero? ? @params[:received_quantity] : @params[:quantity])
  end

end
