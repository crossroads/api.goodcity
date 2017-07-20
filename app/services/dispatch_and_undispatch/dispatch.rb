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
  end
end
