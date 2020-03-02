module Goodcity
  class BaseError < StandardError; end

  class InvalidStateError < BaseError; end

  class OperationsError < BaseError; end

  class InventoryError < BaseError; end

  def factory(base, translation_key)
    Class.new(base) do
      define_method(:initialize) { super(I18n.t(translation_key)) }
    end
  end

  module_function :factory

  UnprocessedError                = factory(OperationsError, 'operations.dispatch.unprocessed_order')
  AlreadyDispatchedError          = factory(OperationsError, 'orders_package.quantity_already_dispatched')
  MissingQuantityError            = factory(OperationsError, 'operations.move.not_enough_at_source')
  NotInventorizedError            = factory(OperationsError, 'operations.generic.not_inventorized')
  AlreadyInventorizedError        = factory(OperationsError, 'operations.generic.already_inventorized')
  UninventoryError                = factory(OperationsError, 'operations.generic.uninventorize_error')
  MissingQuantityforDispatchError = factory(OperationsError, 'operations.dispatch.missing_quantity_for_dispatch')
  BadUndispatchQuantity           = factory(OperationsError, 'operations.undispatch.missing_dispatched_quantity')

  class QuantityDesignatedError < OperationsError
    def initialize(orders)
      order_text = orders.count == 1 ? orders.first.code : "#{orders.count}x"
      super(I18n.t('operations.mark_lost.required_for_orders', orders: order_text))
    end
  end

  class InvalidQuantityError < OperationsError
    def initialize(quantity)
      super(I18n.t('operations.generic.bad_quantity_param', quantity: quantity))
    end
  end

  class InsufficientQuantityError < OperationsError
    def initialize(quantity)
      super(I18n.t('operations.generic.insufficient_quantity', quantity: quantity))
    end
  end

  class InactiveOrderError < OperationsError
    def initialize(order)
      super(I18n.t('operations.generic.inactive_order', code: order.code))
    end
  end

  class MissingQuantityRequiredError < OperationsError
    def initialize(orders)
      order_text = orders.count == 1 ? orders.first.code : "#{orders.count}x"
      super(I18n.t('operations.mark_lost.required_for_orders', orders: order_text))
    end
  end

  class ActionNotAllowedError < OperationsError
    def initialize
      super(I18n.t("operations.generic.action_not_allowed"))
    end
  end
end
