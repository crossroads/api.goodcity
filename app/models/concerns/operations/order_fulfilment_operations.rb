
# Concern that centralizes order fulfilment mechanisms
#
# @example
#   class MyClass
#     include OrderFulfilmentOperations
#   end
#
#   MyClass::Operations.dispatch(orders_package)
#
#
module OrderFulfilmentOperations
  extend Composite

  compose_module :Operations do

    module_function

    ##
    # Undispatch an orders_package
    # Partial undispatch is not currently supported
    #
    # @example
    #   Operations::undispatch(orders_package, to_location: a_location)
    #
    # @param [OrdersPackage] orders_package the orders package to undispatch
    # @param [Location|ID] to_location: the location to undispatch to
    #
    # @raise [StandardError]
    # @raise [ActiveRecord::RecordNotFound]
    #
    # @todo remove stockit references
    #
    def undispatch(ord_pkg, quantity:, to_location:)
      package = ord_pkg.package
      package.inventory_lock do
        assert_can_undispatch(ord_pkg, quantity)
        PackagesInventory.append_undispatch(
          package: package,
          quantity: quantity,
          source: ord_pkg,
          location: Utils.to_model(to_location, Location)
        )

        if ord_pkg.dispatched?
          ord_pkg.update!(state: "designated", sent_on: nil)
          package.save!
        end
      end
    end

    ##
    # Undispatch the already dispatched quantity of an orders_package.
    #
    def undispatch_dispatched_quantity(ord_pkg, to_location:)
      undispatch(ord_pkg, to_location: to_location, quantity: ord_pkg.dispatched_quantity)
    end

    ##
    # Dispatch an orders_package
    # Partial dispatch is not currently supported
    #
    # Changes it's state and moves the packages to the Dispatch location
    #
    # @example
    #   Operations::dispatch(orders_package)
    #
    # @param [OrdersPackage] orders_package the orders package to undispatch
    #
    # @raise [GoodcityError]
    # @raise [ActiveRecord::RecordNotFound]
    #
    def dispatch(ord_pkg, quantity:, from_location:)
      package = ord_pkg.package
      location = Utils.to_model(from_location, Location)
      quantity = quantity.to_i

      package.inventory_lock do

        raise Goodcity::ActionNotAllowedError.with_translation("orders_package.exceed_dispatch_quantity") if quantity > (ord_pkg.quantity - ord_pkg.dispatched_quantity)

        assert_can_dispatch(ord_pkg, quantity, location)

        PackagesInventory.append_dispatch(
          package: package,
          quantity: -1 * quantity.abs,
          source: ord_pkg,
          location: location
        )

        ord_pkg.order.start_dispatching if ord_pkg.order.awaiting_dispatch?

        unless ord_pkg.dispatched? || dispatched_count(ord_pkg) < ord_pkg.quantity
          ord_pkg.dispatch
          package.save!
        end
      end
    end

    # --- HELPERS

    def order_unprocessed?(order)
      Order::ORDER_UNPROCESSED_STATES.include?(order.state)
    end

    def assert_can_dispatch(ord_pkg, quantity, from_location)
      raise Goodcity::AlreadyDispatchedError.new if ord_pkg.dispatched?
      raise Goodcity::UnprocessedError.new if order_unprocessed?(ord_pkg.order)
      raise Goodcity::MissingQuantityforDispatchError.new if quantity > on_hand(ord_pkg.package, from_location)
    end

    def assert_can_undispatch(ord_pkg, quantity)
      raise Goodcity::BadUndispatchQuantityError.new if dispatched_count(ord_pkg) < quantity
    end

    def dispatched_count(ord_pkg)
      PackagesInventory::Computer.dispatched_quantity(orders_package: ord_pkg)
    end

    def on_hand(pkg, location)
      PackagesInventory::Computer.quantity_where(package: pkg, location: location)
    end
  end
end
