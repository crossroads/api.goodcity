module Designation
  class Undesignate < Base
    attr_accessor :orders_package, :package, :quantity_to_deduct, :package_params

    def initialize(package_params)
      self.package_params = package_params
    end

    def undesignate_partially_designated_item
      package_params.each_pair do |_key, package|
        self.orders_package = OrdersPackage.find_by(id: package["orders_package_id"])
        self.package = orders_package.package
        self.quantity_to_deduct = package['quantity']
        remove_designation_of_associated_package
        calculate_total_quantity_and_update_state
      end
    end

    def quantity_after_undesignation
      orders_package.quantity - quantity_to_deduct.to_i
    end

    def remove_designation_of_associated_package
      package.undesignate_from_stockit_order if package.is_singleton_package?
    end

    def calculate_total_quantity_and_update_state
      update_orders_package_state_and_quantity
    end

    def update_orders_package_state_and_quantity
      if quantity_after_undesignation == 0
        orders_package.cancel
      else
        orders_package.quantity = quantity_after_undesignation
        state = "designated"
        orders_package.save and recalculate_package_quantity
      end
    end
  end
end
