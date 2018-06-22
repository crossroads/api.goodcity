module InventoryOperations
  class Base
    attr_accessor :order_id, :package_id, :quantity, :orders_package,
      :current_user, :total_quantity, :package

    def initialize(options = {})
      self.order_id       = options[:order_id]
      self.package_id     = options[:package_id]
      self.quantity       = options[:quantity].to_i
      self.orders_package = find_or_build_orders_package
      self.package        = Package.find(package_id)
      self.current_user ||= User.current_user
    end

    def find_or_build_orders_package
      OrdersPackage.where(order_id: order_id, package_id: package_id).first || OrdersPackage.new(order_id: order_id, package_id: package_id)
    end

    def dispatched_location_id
      @dispatched_location_id ||= Location.dispatch_location.id
    end
  end
end

