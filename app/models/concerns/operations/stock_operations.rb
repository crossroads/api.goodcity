module StockOperations
  extend Composite

  compose_module :Operations do

    module_function

    ##
    # Registers the loss of some package
    #
    # @param [Package] package the package that went missing
    # @param [Integer] quantity the quantity that was lost
    # @param [Location|Id] from the location to negate the quantity from(or its id)
    #
    def register_loss(package, quantity:, from_location:)
      designated_count = PackagesInventory::Computer.designated_quantity_of(package)
      available_count = PackagesInventory::Computer.available_quantity_of(package)

      if (available_count - quantity < designated_count)
        raise MissingQuantityRequiredError.new(
          OrdersPackage.designated.where(package: package).map(&:order).uniq
        )
      end

      PackagesInventory.append_loss(
        package: package,
        quantity: quantity.abs * -1,
        location: from_location
      )
    end

    # --- Exceptions

    class OperationsError < StandardError; end

    class MissingQuantityRequiredError < OperationsError
      def initialize(orders)
        order_text = orders.count == 1 ? orders.first.code : "#{orders.count}x"
        super(I18n.t('operations.mark_lost.required_for_orders', orders: order_text))
      end
    end
  end
end
