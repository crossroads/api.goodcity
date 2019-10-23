require('location_operations')

# Concern that centralizes order fulfilment mechanisms
#
# @example
#   class OrdersPackage < ActiveRecord::Base
#     include OrderFulfilmentOperations
#   end
#
#   OrdersPackage::Operations.dispatch(orders_package)
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
        move(orders_package.quantity, orders_package.package)
          .from(Location.dispatch_location)
          .to(to_location)
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
    def dispatch(orders_package)
      raise StandardError.new(I18n.t('orders_package.already_dispatched')) if orders_package.dispatched?

      order = orders_package.order
      location = orders_package.package.locations.first

      raise Exceptions::UNPROCESSED if order_unprocessed?(order)

      ActiveRecord::Base.transaction do
        # --- Move
        move(orders_package.quantity, orders_package.package)
          .from(location)
          .to(Location.dispatch_location)
        # --- Apply state
        orders_package.dispatch
        # --- Stockit sync
        pkg = Package.find(orders_package.package_id)
        pkg.dispatch_stockit_item(orders_package)
        pkg.save
      end
    end

    def order_unprocessed?(order)
      Order::ORDER_UNPROCESSED_STATES.include?(order.state)
    end

    module Exceptions
      UNPROCESSED = StandardError.new(I18n.t('operations.dispatch.unprocessed_order'))
    end
  end
end