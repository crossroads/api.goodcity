class StockitSyncOrdersPackageJob < ActiveJob::Base
  queue_as :stockit_sync_orders_package_updates

  def perform(package_id, orders_package_id, operation)
    package = Package.find_by(id: package_id)
    orders_package = OrdersPackage.find_by(id: orders_package_id)

    if ((package && orders_package) || (package && operation == "destroy" && orders_package_id))
      case operation
      when "create"
        response = Stockit::OrdersPackageSync.create(package, orders_package)
      when "update"
        response = Stockit::OrdersPackageSync.update(package, orders_package)
      when "destroy"
        response = Stockit::OrdersPackageSync.delete(package, orders_package_id)
      end
      if response && (errors = response["errors"] || response[:errors])
        log_text = "Inventory: #{package.inventory_number} Package: #{package_id}"
        errors.each{ |attribute, error| log_text += " #{attribute}: #{error}" }
        logger.error log_text
      end
    end
  end
end
