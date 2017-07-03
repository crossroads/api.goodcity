module Designation
  class Base
    attr_accessor :order_id, :package, :quantity

    def initialize(package, order_id, quantity, *args)
      self.order_id = order_id
      self.quantity = quantity
      self.package = package
    end

    def designate_stockit_item
      package.designate_to_stockit_order(order_id)
    end

    def dispatched_location_id
      id ||= Location.dispatch_location.id
    end
  end
end
