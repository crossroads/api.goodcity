
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
    # Partial unndispatch is not currently supported
    #
    # @example
    #   Operations::undispatch(orders_package, to_location: a_location)
    #
    # @param [OrdersPackage] orders_package the orders package to undispatch
    # @param [Locationn|ID] to_location: the location to undispatch to
    #
    # @raise [StandardError]
    # @raise [ActiveRecord::RecordNotFound]
    #
    def undispatch(orders_package, to_location:)
      return unless orders_package.dispatched?
      ActiveRecord::Base.transaction do
        # --- Move
        move(orders_package.quantity, orders_package.package,
          from: Location.dispatch_location,
          to: to_location)
        # --- Apply state
        orders_package.update(state: "designated", sent_on: nil)
        # --- Stockit sync
        pkg = Package.find(orders_package.package_id)
        pkg.undispatch_stockit_item
        pkg.save
      end
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
    # @raise [StandardError]
    # @raise [ActiveRecord::RecordNotFound]
    #
    def dispatch(ord_pkg)
      assert_can_dispatch(ord_pkg)
      ActiveRecord::Base.transaction do
        # Move, change state and sync with Stockit
        move(ord_pkg.quantity, ord_pkg.package,
          from: ord_pkg.package.locations.first,
          to: Location.dispatch_location)
        ord_pkg.dispatch
        ord_pkg.package.dispatch_stockit_item(ord_pkg)
        ord_pkg.package.save
      end
    end

    def order_unprocessed?(order)
      Order::ORDER_UNPROCESSED_STATES.include?(order.state)
    end

    def assert_can_dispatch(ord_pkg)
      raise Exceptions::ALREADY_DISPATCHED if ord_pkg.dispatched?
      raise Exceptions::UNPROCESSED if order_unprocessed?(ord_pkg.order)
    end

    module Exceptions
      UNPROCESSED = StandardError.new(I18n.t('operations.dispatch.unprocessed_order'))
      ALREADY_DISPATCHED = StandardError.new(I18n.t('orders_package.already_dispatched'))
    end
  end
end
