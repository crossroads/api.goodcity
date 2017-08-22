module DispatchAndUndispatch
  class Dispatch < Base
    attr_accessor :orders_package, :total_quantity, :orders_package_state, :item

    def initialize(package, order_id, quantity, orders_package_id, item = nil)
      super
      self.orders_package = OrdersPackage.find_by(id: orders_package_id)
      self.item = item
    end

    def dispatch_package
      dispatch_stockit_item(orders_package, package_location_qty, true)
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

    def dispatch_stockit_item(_orders_package=nil, package_location_changes=nil , skip_set_relation_update=false)
      package.skip_set_relation_update = skip_set_relation_update
      package.stockit_sent_on = Date.today
      package.stockit_sent_by = User.current_user
      package.box = nil
      package.pallet = nil
      deduct_dispatch_quantity(package_location_changes) if package_location_changes
      response = Stockit::ItemSync.dispatch(package)
      package.add_errors(response)
    end


    def move_partial_quantity(location_id, package_qty_changes, total_qty)
      package_qty_changes.each do |pckg_qty_param|
        update_existing_package_location_qty(pckg_qty_param["packages_location_id"],  pckg_qty_param["new_qty"])
      end
      update_or_create_qty_moved_to_location(location_id, total_qty)
    end

    def update_or_create_qty_moved_to_location(location_id, total_qty)
      if(packages_location = find_packages_location_with_location_id(location_id))
        packages_location.update(quantity: packages_location.quantity + total_qty.to_i)
      else
        create_associated_packages_location(location_id, total_qty)
      end
    end

    def stockit_item_dispatch
      if package.is_singleton_package? && (orders_package = package.orders_package_with_different_designation)
        package.cancel_designation
        orders_package.update_column(:quantity, package.quantity)
        orders_package.dispatch!
      else
        package.handle_singleton_dispatch_undispatch_with_or_without_designation
      end
      package.update_in_stock_quantity
    end

  def dispatch_set_to_stockit_order(params)
    item.inventory_packages.set_items.each do |pkg|
      self.package = pkg
      orders_package = package.orders_packages.find_by(order_id: params[:order_id])
      if orders_package
        orders_package.dispatch_orders_package
      end
      dispatch_stockit_item(orders_package, nil, true)
      package.valid? and package.save
    end
  end

  end
end
