module DispatchAndUndispatch
  class UnDispatch < Base
    attr_accessor :orders_package, :total_quantity, :orders_package_state

    def initialize(package, order_id, quantity, orders_package_id)
      super
      self.orders_package = OrdersPackage.find_by(id: orders_package_id)
    end

    def undispatch_stockit_item
      package.stockit_sent_on = nil
      package.stockit_sent_by = nil
      package.pallet = nil
      package.box = nil
      response = Stockit::ItemSync.undispatch(package)
      package.add_errors(response)
    end

    def undispatch_orders_package
      orders_package.update(state: "designated", sent_on: nil)
    end

    def update_referenced_or_first_package_location(referenced_package_location, orders_package, location_id)
      if referenced_package_location
        referenced_package_location.update_location_quantity_and_reference(location_id, orders_package.quantity, nil)
      elsif(packages_location = package.packages_locations.first)
        packages_location.update_location_quantity_and_reference(location_id, orders_package.quantity, orders_package.id)
      end
    end
  end
end
