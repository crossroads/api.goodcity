module InventoryOperations
  class Base
    attr_accessor :order_id, :package_id, :quantity, :orders_package,
      :current_user, :total_quantity, :package

    def initialize(package_id, order_id, quantity)
      self.order_id       = order_id
      self.package_id     = package_id
      self.quantity       = quantity.to_i
      self.orders_package = find_or_build_orders_package
      self.package        = Package.find(package_id)
      self.current_user ||= User.current_user
    end

    def find_or_build_orders_package
      OrdersPackage.where(order_id: order_id, package_id: package_id).first || OrdersPackage.new
    end

    def designate
      Goodcity::Designate.new(package_id, order_id, quantity).designate
    end
  end
end
