module DispatchAndUndispatch
  class UnDispatch < Base
    def initialize(orders_package, package, package_location_qty)
      super
    end

    def undispatch_stockit_item
      package.stockit_sent_on = nil
      package.stockit_sent_by = nil
      package.pallet = nil
      package.box = nil
      response = Stockit::ItemSync.undispatch(package)
      package.add_errors(response)
    end

    def move_full_quantity(location_id, orders_package_id)
      orders_package              = package.orders_packages.find_by(id: orders_package_id)
      referenced_package_location = package.packages_locations.find_by(reference_to_orders_package: orders_package_id)

      if(packages_location_record = package.find_packages_location_with_location_id(location_id))
        new_qty = orders_package.quantity + packages_location_record.quantity
        packages_location_record.update(quantity: new_qty, reference_to_orders_package: nil)
        referenced_package_location.destroy
      else
        update_referenced_or_first_package_location(referenced_package_location, orders_package, location_id)
      end
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
