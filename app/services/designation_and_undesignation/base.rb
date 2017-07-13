module DesignationAndUndesignation
  class Base
    attr_accessor :order_id, :package, :quantity, :is_new_orders_package, :orders_package

    def designate_stockit_item
      package.designate_to_stockit_order(order_id)
    end

    def designated_orders_packages
      package.designated_orders_packages
    end

    def dispatched_location_id
      @id ||= Location.dispatch_location.id
    end

    def dispatched_orders_packages
      package.dispatched_orders_packages
    end

    def initialize(package, order_id, quantity, *args)
      self.order_id = order_id
      self.quantity = quantity
      self.package  = package
    end

    def is_valid_for_sync?
      !(orders_package.requested? || GoodcitySync.request_from_stockit)
    end

    def operation_for_sync
      if is_new_orders_package
        "create"
      else
        "update"
      end
    end

    def recalculate_package_quantity
      if is_valid_for_sync?
        update_designation_of_package
        package.update_in_stock_quantity
        StockitSyncOrdersPackageJob.perform_now(package.id, orders_package.id,
          operation_for_sync) unless package.is_singleton_package?
      end
    end

    def undesignate_from_stockit_order
      package.undesignate_from_stockit_order
    end

    def update_designation_of_package
      if package && designated_orders_packages.count == 1
        package.update_designation(designated_orders_packages.first.order_id)
      elsif designated_orders_packages.count == 0 && dispatched_orders_packages.count == 0
        package.remove_designation
      end
    end
  end
end


