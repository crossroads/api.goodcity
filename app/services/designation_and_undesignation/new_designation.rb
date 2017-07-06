module DesignationAndUndesignation
  class NewDesignation < Base
    attr_accessor :order_id, :package_id, :quantity, :package,
      :is_new_orders_package, :orders_package

    def create_new_orders_package
      self.orders_package = OrdersPackage.new
      orders_package.order_id = order_id
      orders_package.package_id = package.id
      orders_package.quantity = quantity
      orders_package.state = "designated"
      orders_package.updated_by =  User.current_user
      self.is_new_orders_package = true
      orders_package.save and recalculate_package_quantity
    end

    def designate_partial_item
      create_new_orders_package
      designate_stockit_item
    end

    def initialize(package, order_id, quantity)
      super
      self.is_new_orders_package = false
      self.orders_package = nil
    end
  end
end
