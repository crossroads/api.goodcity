class Designate
  attr_accessor :package_record, :order_id, :package_id, :quantity

  def initialize(package, order_id, package_id, quantity)
    @package = package
    @order_id   = order_id
    @package_id = package_id
    @quantity   = quantity
  end

  def designate_partial_item
    OrdersPackage.add_partially_designated_item(
      order_id: @order_id,
      package_id: @package_id,
      quantity: @quantity
    )
    designate_stockit_item
  end

  def designate_stockit_item
    @package.designate_to_stockit_order(@order_id)
  end
end
