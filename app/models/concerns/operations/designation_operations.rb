
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
  extend ActiveSupport::Concern

  module Operations

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
      orders_package = init_orders_package(package, to_order);

      assert_can_designate(orders_package, quantity);

      orders_package.quantity = quantity
      orders_package.save
      orders_package

      # PackagesInventory.secured_transaction do
      #   assert_can_designate(package, quantity, to_order)
      #   PackagesInventory.append_undispatch(
      #     package: ord_pkg.package,
      #     quantity: quantity,
      #     source: ord_pkg,
      #     location: Utils.to_model(to_location, Location)
      #   )

      #   if ord_pkg.dispatched?
      #     ord_pkg.update!(state: "designated", sent_on: nil)
      #     ord_pkg.package.undispatch_stockit_item
      #     ord_pkg.package.save
      #   end
      # end
    end

    # --- HELPERS

    def assert_can_designate(orders_package, quantity)
      raise Goodcity::NotInventorizedError.new unless orders_package.package.inventory_number.present?
      raise Goodcity::InvalidQuantityError.new(quantity) unless quantity.positive?
      raise Goodcity::InsufficientQuantityError.new(quantity) unless assignable_quantity(orders_package) >= quantity
      raise Goodcity::InactiveOrderError.new(orders_package.order) unless order_active?(orders_package.order)
    end

    def init_orders_package(package, order)
      OrdersPackage.where(package: package, order: order)
        .first_or_initialize(quantity: 0, state: OrdersPackage::States::DESIGNATED)
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
