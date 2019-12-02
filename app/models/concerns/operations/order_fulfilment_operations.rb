
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
  extend ActiveSupport::Concern

  module Operations
    extend LocationOperations::Operations

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
      return unless ord_pkg.dispatched?

      PackagesInventory.secured_transaction do
        assert_can_undispatch(ord_pkg, quantity)
        PackagesInventory.append_undispatch(
          package: ord_pkg.package,
          quantity: quantity,
          source: ord_pkg,
          location: Utils.to_model(to_location, Location)
        )

        if ord_pkg.dispatched?
          ord_pkg.update!(state: "designated", sent_on: nil)
          ord_pkg.package.undispatch_stockit_item
          ord_pkg.package.save
        end
      end
    end

    ##
    # Undispatch the full quantity of an orders_package.
    # Assumes we live in a stockit world where everything is a singleton
    #
    # @todo remove this from our lives
    #
    def undispatch_singleton(ord_pkg, to_location:)
      undispatch(ord_pkg, to_location: to_location, quantity: ord_pkg.quantity)
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
      PackagesInventory.secured_transaction do
        assert_can_dispatch(ord_pkg, quantity, from_location)
        PackagesInventory.append_dispatch(
          package: ord_pkg.package,
          quantity: -1 * quantity.abs,
          source: ord_pkg,
          location: Utils.to_model(from_location, Location)
        )
        unless ord_pkg.dispatched? || dispatched_count(ord_pkg) < ord_pkg.quantity
          ord_pkg.dispatch
          ord_pkg.package.dispatch_stockit_item(ord_pkg)
          ord_pkg.package.save
        end
      end
    end

    ##
    # Dispatches the full quantity of an orders_package.
    # Assumes we live in a stockit world where everything is a singleton
    #
    # @todo remove this from our lives
    #
    def dispatch_singleton(ord_pkg)
      dispatch(ord_pkg, quantity: ord_pkg.quantity, from_location: ord_pkg.package.locations.first)
    end

    # --- HELPERS

    def order_unprocessed?(order)
      Order::ORDER_UNPROCESSED_STATES.include?(order.state)
    end

    def assert_can_dispatch(ord_pkg, quantity, from_location)
      raise Goodcity::AlredyDispatchedError.new if ord_pkg.dispatched?
      raise Goodcity::UnprocessedError.new if order_unprocessed?(ord_pkg.order)
      raise Goodcity::MissingQuantityforDispatchError.new if quantity > on_hand(ord_pkg.package, from_location)
    end

    def assert_can_undispatch(ord_pkg, quantity)
      raise Goodcity::MissingDispatchedQuantityError.new if dispatched_count(ord_pkg) < quantity
    end

    def dispatched_count(ord_pkg)
      PackagesInventory::Computer.dispatch_quantity_where(source: ord_pkg)
    end

    def on_hand(pkg, location)
      PackagesInventory::Computer.quantity_where(package: pkg, location: location)
    end
  end
end
