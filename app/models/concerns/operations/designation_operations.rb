
# Concern that centralizes designation operations
#
# @example
#   class MyClass
#     include DesignationOperations
#   end
#
#   MyClass::DesignationOperations.designate(package, quantity: 2, to_order: order)
#
#
module DesignationOperations
  extend Composite

  compose_module :Operations do
    module_function
    ##
    # Undispatch an orders_package
    # Partial undispatch is not currently supported
    #
    # @example
    #   Operations.designate(package, quantity: 2, to_order: order)
    #
    # @param [Package|ID] package the package to designate
    # @param [Integer] quantity the amount to designate
    # @param [Order|ID] to_order: the order to designate to
    #
    # @raise [GoodcityError]
    # @raise [ActiveRecord::RecordNotFound]
    #
    # @todo remove stockit references
    #
    def designate(package, quantity:, to_order:)
      quantity = quantity.to_i

      orders_package = init_orders_package(
        Utils.to_model(package, Package),
        Utils.to_model(to_order, Order)
      );

      assert_can_designate(orders_package, quantity);

      orders_package.quantity = quantity
      orders_package.updated_by = User.current_user

      if orders_package.dispatched_quantity.eql?(quantity)
        # Case: we reduced the quantity, enough quantity has been dispatched to change the state of the orders_package
        orders_package.state = OrdersPackage::States::DISPATCHED
        if STOCKIT_ENABLED && !GoodcitySync.request_from_stockit
          # @TODO: Remove after destroying stockit
          orders_package.package.dispatch_stockit_item(orders_package)
          orders_package.package.save
        end
      else
        orders_package.state = OrdersPackage::States::DESIGNATED
      end
      orders_package.save
      orders_package
    end

    # --- HELPERS

    def assert_can_designate(orders_package, quantity)
      raise Goodcity::NotInventorizedError.new unless orders_package.package.inventory_number.present?
      raise Goodcity::InvalidQuantityError.new(quantity) unless quantity.positive?
      raise Goodcity::InsufficientQuantityError.new(quantity) unless assignable_quantity(orders_package) >= quantity
      raise Goodcity::InactiveOrderError.new(orders_package.order) unless order_active?(orders_package.order)
      raise Goodcity::AlreadyDispatchedError.new if quantity < orders_package.dispatched_quantity
    end

    def init_orders_package(package, order)
      OrdersPackage.where(package: package, order: order)
        .first_or_initialize(
          dispatched_quantity: 0,
          quantity: 0,
          state: OrdersPackage::States::DESIGNATED
        )
    end

    def order_active?(order)
      Order::ACTIVE_STATES.include?(order.state)
    end

    def assignable_quantity(orders_package)
      undesignated_qty = PackagesInventory::Computer.available_quantity_of(orders_package.package)
      already_designated_qty = orders_package.quantity
      undesignated_qty + already_designated_qty
    end
  end
end
