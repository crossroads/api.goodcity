module DispatchAndUndispatch
  class Base
    attr_accessor :order_id, :package, :quantity, :orders_package

    def initialize(package, order_id, quantity, *args)
      self.order_id = order_id
      self.quantity = quantity
      self.package  = package
    end
  end
end
