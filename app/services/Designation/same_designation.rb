module Designation
  class SameDesignation < Base
    attr_accessor :orders_package, :total_quantity, :orders_package_state

    def initialize(package, order_id, quantity, orders_package_id)
      super
      self.orders_package = OrdersPackage.find_by(id: orders_package_id)
      self.total_quantity = total_designated_quantity
      self.orders_package_state = orders_package.state
    end

    def update_partial_quantity_of_same_designation
      update_partially_designated_item
      designate_stockit_item
    end

    def update_partially_designated_item
      if(orders_package_state == "cancelled")
        update_state_and_quantity('designated')
      elsif(orders_package_state == "dispatched")
        update_state_and_quantity(orders_package_state)
        update_dispatched_packages_location_quantity(total_quantity)
      else
        update_state_and_quantity(orders_package_state)
      end
    end

    def update_dispatched_location_quantity
      if all_quantity_dispatched?
        package.destroy_other_locations(dispatched_location_idd)
      end
      package.update_location_quantity(total_quantity, dispatched_location_id)
    end

    def update_dispatched_packages_location_quantity(total_quantity)
      location_id = Location.dispatch_location.id
      package.destroy_other_locations(location_id) if total_quantity == package.received_quantity
      package.update_location_quantity(total_quantity, location_id)
    end

    def total_designated_quantity
      orders_package.quantity + quantity.to_i
    end

    def update_state_and_quantity(state)
      orders_package.update(quantity: total_quantity, state: state)
    end

    def all_quantity_dispatched?
      total_quantity == package.received_quantity
    end
  end
end
