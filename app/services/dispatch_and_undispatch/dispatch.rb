module DispatchAndUndispatch
  class Dispatch < Base
    def initialize(package, order_id, quantity)
      super
    end

    def dispatch_package
      dispatch_orders_package
      dispatch_stockit_item
    end
  end
end