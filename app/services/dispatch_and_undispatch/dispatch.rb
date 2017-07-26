module DispatchAndUndispatch
  class Dispatch < Base
    def initialize(package, order_id, quantity)
      super
    end

    def dispatch_package
      package.dispatch_stockit_item(orders_package, package_location_qty, true, self)
      orders_package.dispatch_orders_package
    end


    def deduct_dispatch_quantity(package_qty_changes)
      package_qty_changes.each_pair do |_key, pckg_qty_param|
        update_existing_package_location_qty(pckg_qty_param["packages_location_id"], pckg_qty_param["qty_to_deduct"])
      end
    end

    def update_existing_package_location_qty(packages_location_id, quantity_to_move)
      if(packages_location = package.packages_locations.find_by(id: packages_location_id))
        new_qty = packages_location.quantity - quantity_to_move.to_i
        new_qty == 0 ? packages_location.destroy : packages_location.update_column(:quantity, new_qty)
      end
    end


    def assign_or_update_dispatched_location(orders_package_id, quantity)
      dispatched_location = Location.dispatch_location
      if package.dispatch_from_stockit?
        create_or_update_location_for_dispatch_from_stockit(dispatched_location, orders_package_id, quantity)
      else
        create_dispatched_packages_location_from_gc(dispatched_location, orders_package_id, quantity)
      end
    end

    def create_or_update_location_for_dispatch_from_stockit(dispatched_location, orders_package_id, quantity)
      if(dispatched_packages_location = find_packages_location_with_location_id(dispatched_location.id))
        dispatched_packages_location.update_referenced_orders_package(orders_package_id)
      else
        create_associated_packages_location(dispatched_location.id, quantity, orders_package_id)
      end
    end

    def create_associated_packages_location(location_id, quantity, reference_to_orders_package = nil)
      package.packages_locations.create(
        location_id: location_id,
        quantity: quantity,
        reference_to_orders_package: reference_to_orders_package
      )
    end

    def create_dispatched_packages_location_from_gc(dispatched_location, orders_package_id, quantity)
      unless package.locations.include?(dispatched_location)
        create_associated_packages_location(dispatched_location.id, quantity, orders_package_id)
      end
    end

    def find_packages_location_with_location_id(location_id)
      package.packages_locations.find_by(location_id: location_id)
    end

  end
end
