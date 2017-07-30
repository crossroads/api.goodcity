module DispatchAndUndispatch
  class Base
    attr_accessor :order_id, :package, :quantity, :orders_package, :package_location_qty

    def initialize(orders_package, package, package_location_qty)
      self.package_location_qty = package_location_qty
      self.orders_package = orders_package
      self.package  = package
    end
  end
end
