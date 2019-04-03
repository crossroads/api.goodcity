class Designator
  attr_accessor :package, :params, :order_id, :orders_package

  def initialize(package, package_params)
    @package = package
    @params = package_params
    @order_id = package_params[:order_id].to_i
    @orders_package = @package.orders_packages.new
    @existing_designation =  OrdersPackage.find_by_id(@params[:orders_package_id])
  end

  def designate
    if designating_to_existing_designation?
      add_error_and_return_existing_designation
    else
      undesignate_designated_package if @package.quantity.zero?
      designate_item
    end
  end

  # undesignate_package params is passed from 'undesignate_designated_package'
  def undesignate(undesignate_package = nil)
    packages = undesignate_package ? undesignate_package : @params
    OrdersPackage.undesignate_partially_designated_item(packages)
    @package.undesignate_from_stockit_order
  end

  def undesignate_designated_package
    undesignate_package = {}
    @params[:quantity] = @package.received_quantity
    undesignate_package["0"] = @params
    undesignate(undesignate_package)
  end

  private

  def add_error_and_return_existing_designation
    @existing_designation.errors.add("package_id", "Already designated to this Order")
    @existing_designation
  end

  def designating_to_existing_designation?
    @existing_designation&.order_id == @params[:order_id].to_i
  end

  def designate_item
    @orders_package.order_id = @order_id
    @orders_package.quantity = @params[:quantity_to_designate] ? @params[:quantity_to_designate] :  @params[:quantity]
    @orders_package.updated_by = User.current_user
    @orders_package.state = 'designated'
    @orders_package.save
    @orders_package
  end
end
