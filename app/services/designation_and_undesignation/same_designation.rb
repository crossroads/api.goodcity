module DesignationAndUndesignation
  class SameDesignation < Base
    attr_accessor :orders_package, :total_quantity, :orders_package_state

    def initialize(package, order_id, quantity, orders_package_id)
      super
      self.orders_package = OrdersPackage.find_by(id: orders_package_id)
      self.total_quantity = total_designated_quantity
      self.orders_package_state = orders_package.state
      self.is_new_orders_package = false
    end

    def update_partial_quantity_of_same_designation
      update_partially_designated_item
      designate_stockit_item
    end

    def update_partially_designated_item
      state = orders_package.is_cancelled? ? "designated" : orders_package_state
      update_state_and_quantity(state)
      update_dispatched_packages_location_quantity(total_quantity) if orders_package.is_dispatched?
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
      orders_package.quantity = total_quantity
      orders_package.state = state
      orders_package.save and recalculate_package_quantity
    end

    def all_quantity_dispatched?
      total_quantity == package.received_quantity
    end
  end
end
