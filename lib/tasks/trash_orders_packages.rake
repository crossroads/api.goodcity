# rails goodcity:trash_orders_packages
namespace :goodcity do
  desc 'trash all packages from given orders'
  task trash_orders_packages: :environment do
    trash_order_codes = ["GC-00538", "GC-00910", "GC-00819"]

    trash_order_codes.each do |code|
      order = Order.find_by(code: code)
      order.orders_packages.each do |orders_package|
        if orders_package.state == "dispatched"
          location = package_location(orders_package)
          undispatch_package(orders_package, location)
          undesignate_package(orders_package)
          trash_package(orders_package, location)
        end
      end
    end
  end

  def undispatch_package(orders_package)
    OrdersPackageActions::Operations.undispatch_dispatched_quantity(
      orders_package,
      to_location: location(orders_package)
    )
  end

  def undesignate_package(orders_package)
    orders_package.cancel
  end

  def trash_package(orders_package, location)
    Package::Operations.register_quantity_change(
      orders_package.package,
      quantity: orders_package.quantity,
      location: location.id,
      action: "trash")
  end

  def package_location(orders_package)
    orders_package.package.locations.last
  end
end
