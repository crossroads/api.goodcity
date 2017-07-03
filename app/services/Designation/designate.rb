module Designation
  class Designate < Base
    attr_accessor :order_id, :package_id, :quantity, :package,
      :is_new_orders_package, :orders_package

    def initialize(package, order_id, quantity)
      super
      self.is_new_orders_package = false
      self.orders_package = nil
    end

    def designate_partial_item
      create_new_orders_package
      designate_stockit_item
    end

    def create_new_orders_package
      self.orders_package = OrdersPackage.new
      orders_package.order_id = order_id
      orders_package.package_id = package.id
      orders_package.quantity = quantity
      orders_package.state = "designated"
      orders_package.updated_by =  User.current_user
      self.is_new_orders_package = true
      orders_package.save and recalculate_package_quantity
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
        StockitSyncOrdersPackageJob.perform_now(package_id, orders_package.id, operation_for_sync) unless package.is_singleton_package?
      end
    end

    def update_designation_of_package
      designated_orders_packages = package.orders_packages.where(state: 'designated')
      dispatched_orders_packages = package.orders_packages.where(state: 'dispatched')
      if package && designated_orders_packages.count == 1
        package.update_designation(designated_orders_packages.first.order_id)
      elsif designated_orders_packages.count == 0 && dispatched_orders_packages.count == 0
        package.remove_designation
      end
    end

    def is_valid_for_sync?
      !(orders_package.state == "requested" || GoodcitySync.request_from_stockit)
    end
  end
end
